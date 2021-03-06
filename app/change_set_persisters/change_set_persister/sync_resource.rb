# frozen_string_literal: true
class ChangeSetPersister
  class SyncResource
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      change_set.sync
    end
  end
end
