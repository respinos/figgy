# frozen_string_literal: true

# A base controller for resources, intended for inheritance
class BaseResourceController < ApplicationController
  include ResourceController
  include TokenAuth
  include BrowseEverything::Parameters
  before_action :load_collections, only: [:new, :edit, :update, :create]

  def load_collections
    @collections = query_service.find_all_of_model(model: Collection).map(&:decorate) || []
  end

  def resource
    find_resource(params[:id])
  end

  def change_set
    @change_set ||= change_set_class.new(resource)
  end

  # Resources that allow uploads will use these browse everything methods
  def browse_everything_files
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set.validate(pending_uploads: change_set.pending_uploads + new_pending_uploads)
      buffered_changeset_persister.save(change_set: change_set)
    end

    BrowseEverythingIngestJob.perform_later(resource.id.to_s, self.class.to_s, new_pending_upload_ids) unless new_pending_uploads.empty?

    redirect_to ContextualPath.new(child: resource, parent_id: nil).file_manager
  end

  # Construct the pending download objects
  # @return [Array<PendingUpload>]
  def new_pending_uploads
    return @new_pending_uploads unless @new_pending_uploads.nil?

    @new_pending_uploads = []
    # This is provided within BrowseEverything::Parameters#selected_files
    selected_files.each do |selected_file|
      file_attributes = selected_file.to_h
      auth_header = file_attributes.delete("auth_header")

      new_pending_upload = PendingUpload.new(
        file_attributes.merge(
          id: SecureRandom.uuid,
          created_at: Time.current.utc.iso8601,
          auth_header: auth_header,
          local_id: file_attributes["id"]
        ).symbolize_keys
      )

      @new_pending_uploads << new_pending_upload
    end

    @new_pending_uploads
  end

  # Retrieve the new IDs from the pending uploads
  # @return [Array<String>]
  def new_pending_upload_ids
    ids = new_pending_uploads.map(&:id)
    ids.map(&:to_s)
  end

  # Attach a resource to a parent
  def attach_to_parent
    @change_set = change_set_class.new(find_resource(params[:id]))
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = DynamicChangeSet.new(parent_resource)
    if parent_change_set.validate(parent_resource_params)
      current_member_ids = parent_resource.member_ids
      attached_member_ids = parent_change_set.member_ids
      parent_change_set.member_ids = current_member_ids + attached_member_ids
      obj = nil
      change_set_persister.buffer_into_index do |persist|
        obj = persist.save(change_set: parent_change_set)
      end
      after_update_success(obj, @change_set)
    else
      after_update_failure
    end
  rescue Dry::Types::ConstraintError
    after_update_failure
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    after_update_error e
  end

  # Remove a resource from a parent
  def remove_from_parent
    @change_set = change_set_class.new(find_resource(params[:id]))
    parent_resource = find_resource(parent_resource_params[:id])
    authorize! :update, parent_resource

    parent_change_set = DynamicChangeSet.new(parent_resource)
    if parent_change_set.validate(parent_resource_params)
      current_member_ids = parent_resource.member_ids
      removed_member_ids = parent_change_set.member_ids
      parent_change_set.member_ids = current_member_ids - removed_member_ids

      obj = nil
      change_set_persister.buffer_into_index do |persist|
        obj = persist.save(change_set: parent_change_set)
      end
      after_update_success(obj, @change_set)
    else
      after_update_failure
    end
  rescue Dry::Types::ConstraintError
    after_update_failure
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    after_update_error e
  end

  private

    def parent_resource_params
      params[:parent_resource].to_unsafe_h
    end
end
