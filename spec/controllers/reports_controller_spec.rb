# frozen_string_literal: true
require "rails_helper"

RSpec.describe ReportsController, type: :controller do
  let(:user) { FactoryBot.create(:admin) }

  describe "GET #ephemera_data" do
    let(:project) { FactoryBot.create_for_repository(:ephemera_project, member_ids: box.id) }
    let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: folder.id) }
    let(:folder) { FactoryBot.create_for_repository(:ephemera_folder, contributor: ["contributor 1", "contributor 2"]) }
    let(:data) { "id,title,creator,contributor,publisher\n#{folder.id},test folder,test creator,contributor 1;contributor 2,test publisher\n" }

    before do
      sign_in user
      project
    end

    it "shows folders" do
      get :ephemera_data, params: { project_id: project.id }, format: "html"
      expect(response).to render_template :ephemera_data
      expect(assigns(:resources).first.id).to eq folder.id
    end
    it "allows downloading a CSV file" do
      get :ephemera_data, params: { project_id: project.id }, format: "csv"
      expect(response.body).to eq(data)
      expect(response.headers["Content-Disposition"]).to eq("attachment; filename=\"test-project-data-#{Time.zone.today}.csv\"")
    end
    context "when no project is specified" do
      render_views
      it "has links to each project" do
        get :ephemera_data, params: { formats: :html }
        expect(response).to render_template :ephemera_data
        expect(assigns(:ephemera_projects).first.id).to eq project.id
        expect(response.body).to have_link(project.title.first, href: ephemera_data_path(project.id))
      end
    end
  end

  describe "GET #identifiers_to_reconcile" do
    let(:resource) { FactoryBot.build(:complete_scanned_resource, title: []) }
    let(:resource2) { FactoryBot.build(:complete_scanned_resource, title: []) }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
    let(:data) { "bibid,ark,title\n123456,ark:/99999/fk48675309,Earth rites : fertility rites in pre-industrial Britain\n" }
    before do
      sign_in user
      stub_bibdata(bib_id: "123456")
      stub_ezid(shoulder: "99999/fk4", blade: "8675309")
      change_set = ScannedResourceChangeSet.new(resource)
      change_set.validate(source_metadata_identifier: "123456", state: ["complete"])
      change_set_persister.save(change_set: change_set)

      stub_pulfa(pulfa_id: "MC016_c9616")
      change_set = ScannedResourceChangeSet.new(resource2)
      change_set.validate(source_metadata_identifier: "MC016_c9616")
      change_set_persister.save(change_set: change_set)
    end

    it "displays a html view" do
      get :identifiers_to_reconcile
      expect(response).to render_template :identifiers_to_reconcile
    end
    it "allows downloading a CSV file" do
      get :identifiers_to_reconcile, format: "csv"
      expect(response.body).to eq(data)
    end
  end

  describe "GET #ark_report" do
    let(:bibdata_resource) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "123456", state: ["complete"])
      change_set_persister.save(change_set: change_set)
    end
    let(:pulfa_resource) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "MC016_c9616", state: ["complete"])
      change_set_persister.save(change_set: change_set)
    end
    let(:pulfa_resource2) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "C0652_c0377", state: ["pending"])
      change_set_persister.save(change_set: change_set)
    end
    let(:pulfa_resource3) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "C0652_c0377", state: ["complete"], visibility: ["restricted"])
      change_set_persister.save(change_set: change_set)
    end
    let(:pulfa_resource4) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "RBD1_c13076", state: ["complete"])
      change_set_persister.save(change_set: change_set)
    end

    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), storage_adapter: Valkyrie.config.storage_adapter) }
    let(:data) { "id,component_id,ark,url\n#{pulfa_resource.id},MC016_c9616,ark:/99999/fk48675309,http://test.host/concern/scanned_resources/#{pulfa_resource.id}/manifest\n" }

    before do
      sign_in user
      stub_bibdata(bib_id: "123456")
      stub_pulfa(pulfa_id: "MC016_c9616")
      stub_pulfa(pulfa_id: "C0652_c0377")
      stub_pulfa(pulfa_id: "RBD1_c13076")
      stub_ezid(shoulder: "99999/fk4", blade: "8675309")
      bibdata_resource
      pulfa_resource
      pulfa_resource2
      pulfa_resource3

      # create another resource before the since_date
      Timecop.freeze(Time.zone.local(2000))
      pulfa_resource4
      Timecop.return
    end

    it "displays a html view" do
      get :pulfa_ark_report
      expect(response).to render_template :pulfa_ark_report
    end
    it "allows downloading a CSV file with only the open, complete, pulfa resource included" do
      get :pulfa_ark_report, params: { since_date: "2018-01-01" }, format: "csv"
      expect(response.body).to eq(data)
    end

    context "with an empty since_date" do
      it "does not raise an error" do
        get :pulfa_ark_report, params: { since_date: "" }
        expect { response }.not_to raise_error
      end
    end
  end
end
