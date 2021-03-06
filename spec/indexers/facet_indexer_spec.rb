# frozen_string_literal: true
require "rails_helper"

RSpec.describe FacetIndexer do
  describe ".to_solr" do
    context "when the resource has imported metadata" do
      it "indexes relevant facets" do
        stub_bibdata(bib_id: "123456")
        scanned_resource = FactoryBot.create(:pending_scanned_resource, source_metadata_identifier: "123456", import_metadata: true)
        output = described_class.new(resource: scanned_resource).to_solr

        expect(output[:display_subject_ssim]).to eq scanned_resource.imported_metadata.first.subject
        expect(output[:display_language_ssim]).to eq ["English"]
      end
    end
    context "when the resource has only local metadata" do
      let(:vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Large vocabulary") }
      let(:category) { FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Egg Creatures", member_of_vocabulary_id: [vocabulary.id]) }
      let(:language) { FactoryBot.create_for_repository(:ephemera_term, label: "English", member_of_vocabulary_id: [vocabulary.id]) }
      let(:subject_terms) do
        [FactoryBot.create_for_repository(:ephemera_term, label: "Birdo", member_of_vocabulary_id: [category.id]),
         FactoryBot.create_for_repository(:ephemera_term, label: "Yoshi", member_of_vocabulary_id: [category.id])]
      end
      it "indexes subject, language" do
        folder = FactoryBot.create_for_repository(:ephemera_folder, subject: subject_terms, language: language)
        output = described_class.new(resource: folder).to_solr

        expect(output[:display_subject_ssim]).to contain_exactly("Birdo", "Yoshi", "Egg Creatures")
        expect(output[:display_language_ssim]).to contain_exactly("English")
      end
    end
  end

  context "when the resource has structure" do
    it "indexes its presence" do
      file_set = FactoryBot.create_for_repository(:file_set)
      scanned_resource = FactoryBot.create_for_repository(
        :scanned_resource,
        member_ids: file_set.id,
        thumbnail_id: file_set.id,
        logical_structure: [
          { label: "testing", nodes: [{ label: "Chapter 1", nodes: [{ proxy: file_set.id }] }] }
        ]
      )

      output = described_class.new(resource: scanned_resource).to_solr
      expect(output[:has_structure_bsi]).to be true
    end
  end

  context "when the resource does not have structure" do
    it "indexes its absence" do
      file_set = FactoryBot.create_for_repository(:file_set)
      scanned_resource = FactoryBot.create_for_repository(
        :scanned_resource,
        member_ids: file_set.id,
        thumbnail_id: file_set.id
      )

      output = described_class.new(resource: scanned_resource).to_solr
      expect(output[:has_structure_bsi]).to be false
    end
  end
end
