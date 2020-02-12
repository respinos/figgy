# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::IssuesController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  before do
    sign_in user if user
  end
  describe "new" do
    it_behaves_like "an access controlled new request"
  end
  describe "create" do
    let(:valid_params) do
      {
        metal: ["Bronze"],
        rights_statement: "Test Statement",
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        metal: ["Bronze"]
      }
    end
    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end
  end
  describe "destroy" do
    context "access control" do
      let(:factory) { :numismatic_issue }
      it_behaves_like "an access controlled destroy request"
    end
  end
  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :numismatic_issue }
      it_behaves_like "an access controlled edit request"
    end
    let(:resource) { FactoryBot.create_for_repository(:numismatic_issue) }
    it "retrieves all of the persisted numismatic monograms" do
      monogram1 = FactoryBot.create_for_repository(:numismatic_monogram)
      monogram2 = FactoryBot.create_for_repository(:numismatic_monogram)

      get :edit, params: { id: resource.id.to_s }
      numismatic_monograms = assigns(:numismatic_monograms)
      expect(numismatic_monograms.map(&:id)).to include(monogram1.id)
      expect(numismatic_monograms.map(&:id)).to include(monogram2.id)
    end
    context "when no numismatic monograms have been persisted" do
      it "retrieves an empty array" do
        get :edit, params: { id: resource.id.to_s }
        expect(assigns(:numismatic_monograms)).to eq([])
      end
    end
    it "retrieves an array of facet values to for use in populating select boxes" do
      metadata_adapter = Valkyrie::MetadataAdapter.find(:index_solr)
      change_set_persister = ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
      issue = FactoryBot.create_for_repository(:numismatic_issue,
                                               color: "pink",
                                               denomination: "Drachm",
                                               edge: "milled",
                                               metal: "copper",
                                               object_type: "coin",
                                               shape: "round")
      change_set = DynamicChangeSet.new(issue)
      change_set_persister.save(change_set: change_set)

      get :edit, params: { id: resource.id.to_s }
      colors = assigns(:colors)
      denominations = assigns(:denominations)
      edges = assigns(:edges)
      metals = assigns(:metals)
      object_types = assigns(:object_types)
      shapes = assigns(:shapes)

      expect(colors.first.value).to eq "pink"
      expect(colors.first.hits).to eq 1
      expect(denominations.first.value).to eq "Drachm"
      expect(edges.first.value).to eq "milled"
      expect(metals.first.value).to eq "copper"
      expect(object_types.first.value).to eq "coin"
      expect(shapes.first.value).to eq "round"
    end
  end
  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :numismatic_issue }
      let(:extra_params) { { numismatic_issue: { title: ["Two"] } } }
      it_behaves_like "an access controlled update request"
    end
  end
  describe "GET /concern/numismatic_issues/:id/manifest" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    before do
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
    end
    it "returns a IIIF manifest for a resource with a file" do
      coin = FactoryBot.create_for_repository(:complete_open_coin, files: [file])
      numismatic_issue = FactoryBot.create_for_repository(:complete_open_numismatic_issue, member_ids: [coin.id])
      get :manifest, params: { id: numismatic_issue.id.to_s, format: :json }
      manifest_response = MultiJson.load(response.body, symbolize_keys: true)

      expect(response.headers["Content-Type"]).to include "application/json"
      expect(manifest_response[:manifests].length).to eq 1
      expect(manifest_response[:viewingHint]).to eq nil
    end
  end
end
