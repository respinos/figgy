# frozen_string_literal: true
require "rails_helper"

RSpec.feature "Home Page" do
  let(:user) { FactoryBot.create(:admin) }

  context "in normal mode" do
    before do
      FactoryBot.create_for_repository(:ephemera_project)
      sign_in user
    end

    scenario "displays creation links for administrators" do
      click_link "Add"
      expect(page).to have_link "New Scanned Resource"
      expect(page).to have_link "New Recording", href: new_recording_scanned_resources_path
      expect(page).to have_link "Add a Collection", href: "/collections/new"
      expect(page).to have_link "Add an Archival Media Collection"
      expect(page).to have_link "Manage Roles"
      expect(page).to have_content "Test Project"
      expect(page).to have_link "View Boxes"
      expect(page).to have_link "Add Box"
    end
  end

  context "in read-only mode" do
    before do
      allow(Figgy).to receive(:read_only_mode).and_return(true)
      sign_in user
    end

    scenario "prepends read-only flash notice before other notices" do
      notice = "The site is currently in read-only mode. Successfully authenticated from CAS account."
      expect(page).to have_content notice
    end
  end
end
