# frozen_string_literal: true
require "rails_helper"

RSpec.describe BrowseEverythingFilePaths do
  describe "#parent_path" do
    context "with a path to a directory and a path to a file" do
      subject { described_class.new(selected_files).parent_path }
      let(:single_dir) { Rails.root.join("spec", "fixtures", "ingest_single") }
      let(:selected_files) do
        {
          "0" => { "url" => single_dir.to_s, "file_name" => "color.tif", "file_size" => "100" },
          "1" => { "url" => "#{single_dir}/gray.tif", "file_name" => "gray.tif", "file_size" => "100" }
        }
      end

      it { is_expected.to eq single_dir }
    end
  end
end