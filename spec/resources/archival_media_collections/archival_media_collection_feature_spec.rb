# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.feature "Browsing archival media collections" do
  let(:user) { FactoryBot.create(:admin) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:collection) do
    resource = FactoryBot.build(:collection, change_set: "archival_media_collection")
    change_set = DynamicChangeSet.new(resource, source_metadata_identifier: "C0652")
    change_set_persister.save(change_set: change_set)
  end
  let(:file) { fixture_file_upload("files/audio_file.wav") }
  let(:member) do
    resource = FactoryBot.build(:complete_media_resource)
    change_set = MediaResourceChangeSet.new(resource, member_of_collection_ids: [collection.id], files: [file])
    change_set_persister.save(change_set: change_set)
  end

  before do
    stub_pulfa(pulfa_id: "C0652")
    stub_pulfa(pulfa_id: "C0652_c0377")
    stub_ezid(shoulder: "99999/fk4", blade: "123456")
    member
    sign_in user
  end

  context "when an archival media collection has members" do
    it "links to the members" do
      visit "catalog/#{collection.id}"

      expect(page).to have_link "View all 1 items in this collection"
      expect(page).to have_link "View ARK report"
      expect(page).to have_link "Edit This Archival Media Collection", href: edit_collection_path(collection)
      expect(page).to have_link "Delete This Archival Media Collection", href: collection_path(collection)
    end

    it "links to the file management interface" do
      visit "catalog/#{collection.id}"

      expect(page).to have_link "View all 1 items in this collection"
      expect(page).to have_link "File Manager"
      click_on "File Manager"
      expect(page).to have_button "Upload Files from Server"
    end
  end
end
