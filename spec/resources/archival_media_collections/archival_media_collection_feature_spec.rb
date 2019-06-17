# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Refresh" do
  let(:user) { FactoryBot.create(:admin) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  before do
    sign_in user
  end

  context "archival media collection with members" do
    it "selects the sort_by field and sort members" do
      collection = persister.save(resource: FactoryBot.build(:collection, change_set: "archival_media_collection"))
      persister.save(resource: FactoryBot.build(:complete_media_resource, member_of_collection_ids: [collection.id]))
      visit "catalog/#{collection.id}"

      expect(page).to have_link "View all 1 items in this collection"
      expect(page).to have_link "View ARK report"
      expect(page).to have_link "Edit This Archival Media Collection", href: edit_collection_path(collection)
      expect(page).to have_link "Delete This Archival Media Collection", href: collection_path(collection)
      expect(page).not_to have_link "File Manager"
    end
  end
end
