# frozen_string_literal: false
class ScannedMapDecorator < Valkyrie::ResourceDecorator
  self.display_attributes += Schema::Geo.attributes + [:member_of_collections, :rendered_coverage] - [:thumbnail_id, :coverage]
  self.iiif_manifest_attributes = display_attributes + [:title] - \
                                  Schema::IIIF.attributes - [:visibility, :internal_resource, :rights_statement, :rendered_rights_statement, :thumbnail_id]
  delegate :query_service, to: :metadata_adapter

  def member_of_collections
    @member_of_collections ||=
      begin
        query_service.find_references_by(resource: model, property: :member_of_collection_ids)
                     .map(&:decorate)
                     .map(&:title).to_a
      end
  end

  def members
    @members ||= query_service.find_members(resource: model)
  end

  def scanned_map_members
    @scanned_maps ||= members.select { |r| r.is_a?(ScannedMap) }.map(&:decorate).to_a
  end

  def geo_image_members
    members.select do |member|
      next unless member.respond_to?(:mime_type)
      ControlledVocabulary.for(:geo_image_format).include?(member.mime_type.first)
    end
  end

  def geo_metadata_members
    members.select do |member|
      next unless member.respond_to?(:mime_type)
      ControlledVocabulary.for(:geo_metadata_format).include?(member.mime_type.first)
    end
  end

  def metadata_adapter
    Valkyrie.config.metadata_adapter
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
          I18n.t("valhalla.works.show.attributes.rights_statement.boilerplate").html_safe
        end
    end
  end

  def rendered_coverage
    h.bbox_display(coverage)
  end

  def manageable_structure?
    true
  end

  def attachable_objects
    [ScannedMap]
  end

  def iiif_manifest_attributes
    attributes(self.class.iiif_manifest_attributes)
  end
end