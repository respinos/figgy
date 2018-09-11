# frozen_string_literal: true
class ScannedResourceDecorator < Valkyrie::ResourceDecorator
  display Schema::Common.attributes, :rendered_ocr_language, :rendered_holding_location, :member_of_collections, :rendered_actors
  suppress :thumbnail_id, :imported_author, :source_jsonld, :source_metadata, :sort_title, :ocr_language, :rights_statement, :actor

  display_in_manifest displayed_attributes, :location
  suppress_from_manifest Schema::IIIF.attributes,
                         :visibility,
                         :internal_resource,
                         :rights_statement,
                         :rendered_rights_statement,
                         :rendered_ocr_language,
                         :ocr_language,
                         :thumbnail_id

  delegate(*Schema::Common.attributes, to: :primary_imported_metadata, prefix: :imported)
  delegate :members, :collections, to: :wayfinder

  # TODO: Rename this to decorated_scanned_resources
  def volumes
    wayfinder.decorated_scanned_resources
  end

  # TODO: Rename this to decorated_file_sets
  def file_sets
    wayfinder.decorated_file_sets
  end

  # TODO: Remove this. Parents should be parent resources.
  def parents
    collections
  end

  # TODO: Rename this to decorated_parent
  def decorated_parent_resource
    @decorated_parent_resource ||= wayfinder.decorated_parent
  end

  def rendered_rights_statement
    rights_statement.map do |rights_statement|
      term = ControlledVocabulary.for(:rights_statement).find(rights_statement)
      next unless term
      h.link_to(term.label, term.value) +
        h.content_tag("br") +
        h.content_tag("p") do
          term.definition.html_safe
        end +
        h.content_tag("p") do
          I18n.t("works.show.attributes.rights_statement.boilerplate").html_safe
        end
    end
  end

  def rendered_holding_location
    value = holding_location
    return unless value.present?
    vocabulary = ControlledVocabulary.for(:holding_location)
    value.map do |holding_location|
      vocabulary.find(holding_location).label
    end
  end

  def rendered_ocr_language
    return unless ocr_language.present?
    vocabulary = ControlledVocabulary.for(:ocr_language)
    ocr_language.map do |language|
      vocabulary.find(language).label
    end
  end

  def manageable_structure?
    true
  end

  def attachable_objects
    [ScannedResource]
  end

  # Access the resource attributes imported from an external service
  # @return [Hash] a Hash of all of the resource attributes
  def imported_attributes
    @imported_attributes ||= ImportedAttributes.new(subject: self, keys: self.class.displayed_attributes).to_h
  end

  # Display the resource attributes
  # @return [Hash] a Hash of all of the resource attributes
  def display_attributes
    super.reject { |k, v| imported_attributes.fetch(k, nil) == v }
  end

  # Access the resources attributes exposed for the IIIF Manifest metadata
  # @return [Hash] a Hash of all of the resource attributes
  def iiif_manifest_attributes
    super.merge imported_attributes
  end

  def collection_slugs
    @collection_slugs ||= collections.flat_map(&:slug)
  end

  def human_readable_type
    return model.human_readable_type if model.id.blank? || wayfinder.scanned_resources_count.zero?
    I18n.translate("models.multi_volume_work", default: "Multi Volume Work")
  end

  def imported_attribute(attribute_key)
    return primary_imported_metadata.send(attribute_key) if primary_imported_metadata.try(attribute_key)
    Array.wrap(primary_imported_metadata.attributes.fetch(attribute_key, []))
  end

  def imported_language
    imported_attribute(:language).map do |language|
      ControlledVocabulary.for(:language).find(language).label
    end
  end
  alias display_imported_language imported_language

  def created
    output = super
    return if output.blank?
    output.map { |value| Date.parse(value.to_s).strftime("%B %-d, %Y") }
  end

  def imported_created
    output = imported_attribute(:created)
    return if output.blank?
    output.map { |value| Date.parse(value.to_s).strftime("%B %-d, %Y") }
  end

  def pdf_file
    pdf = file_metadata.find { |x| x.mime_type == ["application/pdf"] }
    pdf if pdf && Valkyrie::StorageAdapter.find(:derivatives).find_by(id: pdf.file_identifiers.first)
  rescue Valkyrie::StorageAdapter::FileNotFound
    nil
  end

  def rendered_actors
    Array.wrap(actor).flat_map do |actor|
      if actor.is_a?(String)
        actor
      elsif actor.is_a?(Grouping)
        actor.elements.map(&:to_s)
      else
        actor.to_s
      end
    end
  end
end
