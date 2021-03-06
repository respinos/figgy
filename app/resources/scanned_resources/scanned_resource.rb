# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`
class ScannedResource < Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :imported_metadata, Valkyrie::Types::Set.of(ImportedMetadata).optional
  attribute :state
  attribute :logical_structure, Valkyrie::Types::Array.of(Structure.optional).optional
  attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.of(FileMetadata.optional)
  attribute :change_set, Valkyrie::Types::String
  attribute :archival_collection_code, Valkyrie::Types::String
  attribute :date_range
  attribute :sender, Valkyrie::Types::Array.of(NameWithPlace).meta(ordered: true)
  attribute :recipient, Valkyrie::Types::Array.of(NameWithPlace).meta(ordered: true)
  attribute :upload_set_id, Valkyrie::Types::ID

  def self.can_have_manifests?
    true
  end

  def to_s
    "#{human_readable_type}: #{title&.to_sentence}"
  end

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def pdf_file
    file_metadata.find do |file|
      file.mime_type == ["application/pdf"]
    end
  end

  def title
    primary_imported_metadata.title.present? ? primary_imported_metadata.title : attributes[:title]
  end

  # Determines if this is an image resource
  # @return [TrueClass, FalseClass]
  def image_resource?
    return false if change_set == "recording"
    true
  end

  def media_resource?
    return true if change_set == "recording"
    false
  end
end
