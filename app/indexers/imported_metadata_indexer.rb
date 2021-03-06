# frozen_string_literal: true
class ImportedMetadataIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.try(:primary_imported_metadata)
    identifier_properties.merge(primary_imported_properties)
  end

  private

    def identifier_properties
      {
        local_identifier_ssim: imported_or_existing(attribute: :local_identifier),
        call_number_tsim: imported_or_existing(attribute: :call_number),
        container_tesim: imported_or_existing(attribute: :container)
      }
    end

    def imported_or_existing(attribute:)
      resource.primary_imported_metadata.send(attribute) ? resource.primary_imported_metadata.send(attribute) : resource.try(attribute)
    end

    def primary_imported_properties
      resource.primary_imported_metadata.to_h.except(*suppressed_keys).map do |k, v|
        ["imported_#{k}_tesim", format_values(v)]
      end.to_h
    end

    def format_values(value)
      return value.map(&:to_s) if value.is_a?(Array)
      return value.to_s if value
    end

    def suppressed_keys
      [
        :id,
        :internal_resource,
        :created_at,
        :updated_at,
        :new_record,
        :import_url,
        :label,
        :nav_date,
        :ocr_language,
        :pdf_type,
        :relative_path,
        :rendered_rights_statement,
        :rights_statement,
        :source_jsonld,
        :source_metadata,
        :source_metadata_identifier,
        :start_canvas,
        :viewing_direction,
        :viewing_hint,
        :visibility
      ]
    end
end
