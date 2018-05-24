# frozen_string_literal: true
class RasterResourceWayfinder < BaseWayfinder
  relationship_by_property :members, property: :member_ids
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  relationship_by_property :raster_resources, property: :member_ids, model: RasterResource
  relationship_by_property :vector_resources, property: :member_ids, model: VectorResource
  relationship_by_property :collections, property: :member_of_collection_ids
  inverse_relationship_by_property :parents, property: :member_ids, singular: true
  inverse_relationship_by_property :raster_resource_parents, property: :member_ids, model: RasterResource
  inverse_relationship_by_property :scanned_map_parents, property: :member_ids, model: ScannedMap

  def geo_members
    @geo_members ||=
      begin
        members.select do |member|
          next unless member.respond_to?(:mime_type)
          ControlledVocabulary.for(:geo_raster_format).include?(member.mime_type.first)
        end
      end
  end

  def geo_metadata_members
    @geo_metadata_members ||=
      begin
        members.select do |member|
          next unless member.respond_to?(:mime_type)
          ControlledVocabulary.for(:geo_metadata_format).include?(member.mime_type.first)
        end
      end
  end
end
