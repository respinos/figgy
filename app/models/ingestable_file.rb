# frozen_string_literal: true
class IngestableFile < Valkyrie::Resource
  attribute :file_path, Valkyrie::Types::String
  attribute :mime_type, Valkyrie::Types::String
  attribute :original_filename, Valkyrie::Types::String
  # Hash of attributes to apply to the FileSet created when ingesting this file.
  attribute :container_attributes, Valkyrie::Types::Hash
  # Hash of attributes to apply to the FileMetadata node when ingesting this
  # file.
  attribute :node_attributes, Valkyrie::Types::Hash
  attribute :use
  # On true: Makes `path` return the file_path directly of the file. Usually for when the
  #   storage adapter is configured to copy a file instead of `mv`. It's more
  #   efficient, but if the storage adapter is configured to use `mv` then the
  #   file will dissapear from its old location.
  # On false: `path` will return a copied version of this file, so if a storage
  #   adapter is configured to use `mv` it won't move this file from its original
  #   location.
  # Default is false.
  # This will usually be set to false, it's only set to true in cases where
  #   we're importing files from disk and the import task is using the
  #   `lae_storage` or `disk_via_copy` storage adapter, which is the case for the
  #   various bulk ingest jobs.
  attribute :copyable, Valkyrie::Types::Bool

  def content_type
    mime_type
  end

  def path
    return file_path if copyable
    copied_file_name
  end

  private

    def copied_file_name
      return @copied_file_name if @copied_file_name
      basename = Pathname.new(file.path).basename
      @copied_file_name = Tempfile.new([basename.to_s.split(".").first, basename.extname]).tap do |f|
        FileUtils.cp(File.open(file.path).path, f.path)
      end.path
    end

    def file
      @file ||= File.open(file_path)
    end
end
