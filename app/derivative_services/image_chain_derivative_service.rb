# frozen_string_literal: true
class ImageChainDerivativeService < ImageDerivativeService
  class Factory < ImageDerivativeService::Factory
    def new(id:)
      ImageChainDerivativeService.new(id: id, change_set_persister: change_set_persister, image_config: image_config)
    end
  end

  # @attr callbacks methods or procs for generating different types of
  # derivatives
  class_attribute :callbacks
  self.callbacks = []

  # @param callback
  # @param callback_args [Hash]
  def self.register_callback(callback, **callback_args)
    values = {
      name: callback,
      args: callback_args
    }
    new_callback = OpenStruct.new(values)

    callbacks << new_callback
  end

  #
  # @param input_file [Pathname]
  # @param format [String]
  # @param width [Integer]
  # @param height [Integer]
  # @param output_file [File]
  def self.run_derivatives(input_file:, format:, width:, height:, output_file:)
    Hydra::Derivatives::ImageDerivatives.create(
      input_file,
      outputs: [
        {
          label: :thumbnail,
          format: format,
          size: "#{width}x#{height}>",
          url: URI("file://#{output_file.path}")
        }
      ]
    )
  end

  # Constructor
  # @param id
  # @param change_set_persister
  # @param image_config
  def initialize(id:, change_set_persister:, image_config:)
    @id = id
    @change_set_persister = change_set_persister
    @image_config = image_config
    # super
    @input_filenames = []
    @output_files = []

    register_callbacks
  end

  # Create the derivatives and persist them as file metadata nodes for the
  # resource
  def create_derivatives
    run_derivative_callbacks
    change_set.files = [build_file]
    change_set_persister.save(change_set: change_set)
    update_error_message(message: nil) if target_file.error_message.present?
  rescue StandardError => error
    update_error_message(message: error.message)
    raise error
  end

  private

    # Access the queue for the input filenames
    # @return [Pathname]
    def next_input_filename
      @input_filenames.pop
    end

    # Access the queue for the output files
    # @return [Tempfile]
    def next_output_file
      @output_files.pop
    end

    # Register a class method as a callback for generating derivatives
    def register_default_callback
      self.class.register_callback(:run_derivatives,
                                   input_file: next_input_filename,
                                   format: format,
                                   width: width,
                                   height: height,
                                   output_file: next_output_file)
    end

    # Construct the file handler for the generation of greyscale derivatives
    # @return [Tempfile]
    def greyscale_output
      @greyscale_file ||= Tempfile.new
    end

    # Construct the file handler for the generation of default derivatives
    # @return [Tempfile]
    def default_output
      @default_file ||= Tempfile.new
    end

    # Register all callbacks for this class
    def register_callbacks
      @input_filenames << filename
      @output_files << greyscale_output
      register_default_callback

      greyscale_output_path = Pathname.new(greyscale_output.path)
      @input_filenames << greyscale_output_path
      @output_files << default_output
      register_default_callback
    end

    # Run the callbacks registered for generating derivatives
    def run_derivative_callbacks
      self.class.callbacks.each do |signature|
        self.class.send(signature.name, **signature.args)
      end
    end
end
