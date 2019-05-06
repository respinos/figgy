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
  # @param input_file
  # @param format
  # @param width
  # @param height
  # @param output_file
  def self.run_greyscale_derivatives(input_file:, format:, width:, height:, output_file:)
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

  #
  # @param input_file
  # @param format
  # @param width
  # @param height
  # @param output_file
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

  attr_reader :image_config, :use, :change_set_persister, :id
  delegate :width, :height, :format, :output_name, to: :image_config
  delegate :mime_type, to: :target_file
  delegate :query_service, :storage_adapter, to: :change_set_persister
  def initialize(id:, change_set_persister:, image_config:)
    @id = id
    @change_set_persister = change_set_persister
    @image_config = image_config

    self.class.register_callback(:run_derivatives,
                                 input_file: filename,
                                 format: format,
                                 width: width,
                                 height: height,
                                 output_file: temporary_output)
  end

  # Run the callbacks registered for generating derivatives
  def run_derivative_callbacks
    self.class.callbacks.each do |signature|
      self.class.send(signature.name, **signature.args)
    end
  end

  def create_derivatives
    run_derivative_callbacks
    change_set.files = [build_file]
    change_set_persister.save(change_set: change_set)
    update_error_message(message: nil) if target_file.error_message.present?
  rescue StandardError => error
    update_error_message(message: error.message)
    raise error
  end
end
