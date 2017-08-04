# frozen_string_literal: true
require 'rails_helper'

RSpec.describe OsdModalHelper do
  describe "#osd_modal_for" do
    context "when not given an ID" do
      it "yields" do
        output = helper.osd_modal_for(nil) do
          "bla"
        end
        expect(output).to eq "bla"
      end
    end
  end

  describe "#figgy_thumbnail_path" do
    context "when given a two-level deep resource" do
      it "uses the fileset thumbnail ID" do
        file_set = FactoryGirl.create_for_repository(:file_set)
        book = FactoryGirl.create_for_repository(:scanned_resource, thumbnail_id: file_set.id)
        parent_book = FactoryGirl.create_for_repository(:scanned_resource, thumbnail_id: book.id)

        expect(helper.figgy_thumbnail_path(parent_book)).to include file_set.id.to_s
      end
    end
  end
end
