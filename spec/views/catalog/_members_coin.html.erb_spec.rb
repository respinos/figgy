# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_members_coin" do
  context "when a Coin has members" do
    let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }
    let(:accession) { FactoryBot.create_for_repository(:numismatic_accession, accession_number: 234) }
    let(:citation) { FactoryBot.create_for_repository(:numismatic_citation, numismatic_reference_id: [reference.id]) }
    let(:artist) { FactoryBot.create_for_repository(:numismatic_artist) }
    let(:coin) { FactoryBot.create_for_repository(:coin, numismatic_citation_ids: [citation.id], accession_number: accession.accession_number, member_ids: [citation.id, artist.id]) }
    let(:document) { Valkyrie::MetadataAdapter.find(:index_solr).resource_factory.from_resource(resource: coin) }
    let(:solr_document) { SolrDocument.new(document) }
    let(:change_set) { DynamicChangeSet.new(solr_document.resource) }

    before do
      assign :document, solr_document
      assign :resource, solr_document.resource
      assign :change_set, change_set
      render
    end

    it "has a Citation table" do
      expect(rendered).to have_selector "h2", text: "Citations"
      expect(rendered).to have_link "View", href: solr_document_path(citation)
      expect(rendered).to have_link "Edit", href: edit_numismatic_citation_path(citation)
    end

    it "doesn't have an Artist table" do
      expect(rendered).not_to have_selector "h2", text: "Artists"
      expect(rendered).not_to have_link "View", href: solr_document_path(artist)
      expect(rendered).not_to have_link "Edit", href: edit_numismatic_artist_path(artist)
    end
  end
end
