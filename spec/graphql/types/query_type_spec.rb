# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::QueryType do
  let(:context) { { ability: ability, change_set_persister: change_set_persister } }
  let(:ability) { instance_double(Ability) }
  let(:change_set_persister) { GraphqlController.change_set_persister }

  describe "field definitions" do
    subject { described_class }
    let(:context) { {} }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:resource).of_type(Types::Resource) }
    it { is_expected.to have_field(:resourcesByBibid) }
  end

  context "when the user can discover the resource" do
    before do
      allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
    end

    describe "resource field" do
      subject { described_class.fields["resource"] }
      it { is_expected.to accept_arguments(id: "ID!") }

      it "can return a resource by ID" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        type = described_class.new(nil, context)
        expect(type.resource(id: scanned_resource.id.to_s)).to be_a ScannedResource
      end

      it "can return a FileSet" do
        file_set = FactoryBot.create_for_repository(:file_set)
        type = described_class.new(nil, context)
        expect(type.resource(id: file_set.id.to_s)).to be_a FileSet
      end
    end
  end

  describe "#resources_by_bibid" do
    subject { described_class.fields["resourcesByBibid"] }
    it { is_expected.to accept_arguments(bibId: "String!") }

    context "when a user can discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end

      it "can return a resource by its bibid" do
        stub_bibdata(bib_id: "7214786")
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibid(bib_id: "7214786").map(&:id)).to eq [scanned_resource.id]
      end

      it "can return a raster resource by its bibid" do
        stub_bibdata(bib_id: "7214786")
        raster_resource = FactoryBot.create_for_repository(:raster_resource, source_metadata_identifier: "7214786")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibid(bib_id: "7214786").map(&:id)).to eq [raster_resource.id]
      end

      it "can return a vector resource by its bibid" do
        stub_bibdata(bib_id: "7214786")
        vector_resource = FactoryBot.create_for_repository(:vector_resource, source_metadata_identifier: "7214786")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibid(bib_id: "7214786").map(&:id)).to eq [vector_resource.id]
      end
    end

    context "when the user can't discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(false)
      end

      it "returns nothing" do
        stub_bibdata(bib_id: "7214786")
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibid(bib_id: "7214786")).to eq []
      end
    end

    context "when the resource does not have a defined graphql type" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end

      it "returns nothing" do
        stub_bibdata(bib_id: "7214786")
        FactoryBot.create_for_repository(:media_resource, source_metadata_identifier: "7214786")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibid(bib_id: "7214786")).to eq []
      end
    end
  end

  describe "#resources_by_bibids" do
    subject { described_class.fields["resourcesByBibids"] }
    it { is_expected.to accept_arguments(bibIds: "[String!]!") }

    context "when a user can discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end

      it "can return resources by its bibid" do
        stub_bibdata(bib_id: "7214786")
        stub_bibdata(bib_id: "8543429")
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        scanned_resource2 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "8543429")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibids(bib_ids: ["7214786", "8543429"]).map(&:id)).to contain_exactly(scanned_resource.id, scanned_resource2.id)
      end
    end

    context "when the user can't discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(false)
      end

      it "returns nothing" do
        stub_bibdata(bib_id: "7214786")
        stub_bibdata(bib_id: "8543429")
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "8543429")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibids(bib_ids: ["7214786", "8543429"])).to eq []
      end
    end

    context "when one resource does not have a defined graphql type" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end

      it "returns the resource with the defined type only" do
        stub_bibdata(bib_id: "7214786")
        stub_bibdata(bib_id: "8543429")
        scanned_map = FactoryBot.create_for_repository(:scanned_map, source_metadata_identifier: "7214786")
        FactoryBot.create_for_repository(:media_resource, source_metadata_identifier: "8543429")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibids(bib_ids: ["7214786", "8543429"]).map(&:id)).to contain_exactly(scanned_map.id)
      end
    end
  end

  describe "#resources_by_coin_number" do
    context "when a user can discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end

      it "can return a resource by its coin number" do
        coin = FactoryBot.create_for_repository(:coin, coin_number: 1)
        type = described_class.new(nil, context)
        expect(type.resources_by_coin_number(coin_number: "1").map(&:id)).to eq [coin.id]
      end
    end

    context "when the user can't discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(false)
      end

      it "returns nothing" do
        FactoryBot.create_for_repository(:coin, coin_number: 1)
        type = described_class.new(nil, context)
        expect(type.resources_by_coin_number(coin_number: "1").map(&:id)).to eq []
      end
    end
  end

  describe "#resources_by_coin_numbers" do
    context "when a user can discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end

      it "can return resources by coin numbers" do
        coin = FactoryBot.create_for_repository(:coin, coin_number: 1)
        coin2 = FactoryBot.create_for_repository(:coin, coin_number: 2)
        type = described_class.new(nil, context)
        expect(type.resources_by_coin_numbers(coin_numbers: ["1", "2"]).map(&:id)).to contain_exactly(coin.id, coin2.id)
      end
    end

    context "when the user can't discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(false)
      end

      it "returns nothing" do
        stub_bibdata(bib_id: "7214786")
        FactoryBot.create_for_repository(:coin, coin_number: 1)
        FactoryBot.create_for_repository(:coin, coin_number: 2)
        type = described_class.new(nil, context)
        expect(type.resources_by_coin_numbers(coin_numbers: ["1", "2"]).map(&:id)).to eq []
      end
    end
  end

  describe "#resources_by_orangelight_id" do
    subject { described_class.fields["resourcesByOrangelightId"] }
    it { is_expected.to accept_arguments(id: "String!") }

    context "when the user can discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end

      it "can return a resource by its bibid" do
        stub_bibdata(bib_id: "7214786")
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        type = described_class.new(nil, context)
        expect(type.resources_by_orangelight_id(id: "7214786").map(&:id)).to eq [scanned_resource.id]
      end

      it "can return a resource by its coin id" do
        coin = FactoryBot.create_for_repository(:coin, coin_number: 1)
        type = described_class.new(nil, context)
        expect(type.resources_by_orangelight_id(id: "coin-1").map(&:id)).to eq [coin.id]
      end
    end
  end

  describe "#resources_by_figgy_ids" do
    subject { described_class.fields["resourcesByFiggyIds"] }
    it { is_expected.to accept_arguments(ids: "[ID!]!") }

    context "when a user can discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end
      it "can return resources by figgy_id" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        monogram = FactoryBot.create_for_repository(:numismatic_monogram)
        type = described_class.new(nil, context)
        expect(type.resources_by_figgy_ids(ids: [scanned_resource.id, monogram.id]).map(&:id)).to contain_exactly(scanned_resource.id, monogram.id)
      end
    end
    context "when the user can't discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(false)
      end

      it "returns nothing" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        monogram = FactoryBot.create_for_repository(:numismatic_monogram)
        type = described_class.new(nil, context)
        expect(type.resources_by_figgy_ids(ids: [scanned_resource.id, monogram.id]).map(&:id)).to eq []
      end
    end
  end

  describe "#resources_by_orangelight_ids" do
    subject { described_class.fields["resourcesByOrangelightIds"] }
    it { is_expected.to accept_arguments(ids: "[String!]!") }

    context "when a user can discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(true)
      end

      it "can return resources by bibids" do
        stub_bibdata(bib_id: "7214786")
        stub_bibdata(bib_id: "8543429")
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        scanned_resource2 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "8543429")
        type = described_class.new(nil, context)
        expect(type.resources_by_orangelight_ids(ids: ["7214786", "8543429"]).map(&:id)).to contain_exactly(scanned_resource.id, scanned_resource2.id)
      end

      it "can return resources by coin_ids" do
        coin = FactoryBot.create_for_repository(:coin, coin_number: 43)
        coin2 = FactoryBot.create_for_repository(:coin, coin_number: 42)
        type = described_class.new(nil, context)
        expect(type.resources_by_orangelight_ids(ids: ["coin-43", "coin-42"]).map(&:id)).to contain_exactly(coin.id, coin2.id)
      end

      it "can return resources by bibid and coin_id" do
        stub_bibdata(bib_id: "7214786")
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        coin = FactoryBot.create_for_repository(:coin, coin_number: 45)
        type = described_class.new(nil, context)
        expect(type.resources_by_orangelight_ids(ids: ["7214786", "coin-45"]).map(&:id)).to contain_exactly(scanned_resource.id, coin.id)
      end
    end

    context "when the user can't discover the resource" do
      before do
        allow(ability).to receive(:can?).with(:discover, anything).and_return(false)
      end

      it "returns nothing" do
        stub_bibdata(bib_id: "7214786")
        stub_bibdata(bib_id: "8543429")
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "8543429")
        type = described_class.new(nil, context)
        expect(type.resources_by_orangelight_ids(ids: ["7214786", "8543429"])).to eq []
      end
    end
  end

  context "when the user cannot discover the resource" do
    before do
      allow(ability).to receive(:can?).with(:discover, anything).and_return(false)
    end

    it "returns nothing" do
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
      type = described_class.new(nil, context)
      expect(type.resource(id: scanned_resource.id.to_s)).to be_nil
    end
  end

  context "when the resource cannot be retrieved" do
    before do
      allow(Valkyrie.logger).to receive(:error)
    end

    it "returns nothing" do
      type = described_class.new(nil, context)
      expect(type.resource(id: "non-existent")).to be_nil
      expect(Valkyrie.logger).to have_received(:error).with("Failed to retrieve the resource non-existent for a GraphQL query")
    end
  end
end
