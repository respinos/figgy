# frozen_string_literal: true
class ScannedMapWayfinder < BaseWayfinder
  relationship_by_property :members, property: :member_ids
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  relationship_by_property :raster_resources, property: :member_ids, model: RasterResource
  relationship_by_property :scanned_maps, property: :member_ids, model: ScannedMap
  relationship_by_property :collections, property: :member_of_collection_ids
  inverse_relationship_by_property :scanned_map_parents, property: :member_ids, model: ScannedMap
  inverse_relationship_by_property :parents, property: :member_ids, singular: true

  def geo_image_members
    @geo_members ||=
      begin
        members.select do |member|
          next unless member.respond_to?(:mime_type) && member.mime_type
          ControlledVocabulary.for(:geo_image_format).include?(member.mime_type.first)
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

  def members_with_parents
    @members_with_parents ||= members.map do |member|
      member.loaded[:parents] = [resource]
      member
    end
  end

  def logical_structure_members
    @logical_structure_members ||= generate_logical_structure_members
  end

  private

    # To display and save logical order correctly, this method replaces ScannedMap members that have no ScannedMap children
    # with their corresponding geo member (TIFF) FileSet. Geo resources are unusual in that each resource has one corresponding
    # geo member. An atlas with multiple maps, for example, will be a set of multiple ScannedMaps with each resource corresponding
    # to a single map. ScannedMap members with ScannedMap children are analogous to a volume in a multi-volume work.
    def generate_logical_structure_members
      members_with_parents.map do |member|
        decorator = member.decorate
        if decorator.respond_to?(:scanned_map_members) && decorator.scanned_map_members.empty?
          member.decorate.geo_members.first
        else
          member
        end
      end.compact
    end
end
