# frozen_string_literal: true
class BulkUpdateJob < ApplicationJob
  def perform(ids:, args:)
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      ids.each do |id|
        resource = query_service.find_by(id: id)
        change_set = DynamicChangeSet.new(resource).prepopulate!
        attributes = {}.tap do |attrs|
          attrs[:state] = "complete" if args[:mark_complete] && !resource.state.include?("complete")
        end
        change_set.validate(attributes)
        if change_set.changed?
          raise "Bulk update failed for batch #{ids} with args #{args} due to invalid change set on resource #{id}" unless change_set.valid?
          buffered_change_set_persister.save(change_set: change_set)
        end
      end
    end
  end

  private

    def query_service
      metadata_adapter.query_service
    end

    def metadata_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    def storage_adapter
      Valkyrie::StorageAdapter.find(:disk_via_copy)
    end

    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: metadata_adapter,
        storage_adapter: storage_adapter
      )
    end
end