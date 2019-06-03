# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"
include ActionDispatch::TestProcess

RSpec.describe ScannedMapDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    ScannedMapDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:scanned_map) do
    change_set_persister.save(change_set: ScannedMapChangeSet.new(ScannedMap.new, files: [file]))
  end
  let(:scanned_map_members) { query_service.find_members(resource: scanned_map) }
  let(:valid_resource) { scanned_map_members.first }
  let(:valid_change_set) { DynamicChangeSet.new(valid_resource) }
  let(:valid_id) { valid_change_set.id }

  describe "#valid?" do
    subject(:valid_file) { derivative_service.new(id: valid_change_set.id) }

    context "when given a valid mime_type" do
      it { is_expected.to be_valid }
    end
  end

  context "with a scanned map tif" do
    it "creates a JPEG thumbnail and attaches it to the fileset" do
      derivative_service.new(id: valid_change_set.id).create_derivatives
      reloaded = query_service.find_by(id: valid_resource.id)
      thumbnail = reloaded.thumbnail_files.first
      expect(thumbnail).to be_present
      thumbnail_file = Valkyrie::StorageAdapter.find_by(id: thumbnail.file_identifiers.first)
      image = MiniMagick::Image.open(thumbnail_file.disk_path)
      expect(image.width).to eq 200
      expect(image.height).to eq 287
    end
  end

  context "with a malformed scanned map tiff" do
    let(:file) { fixture_file_upload("files/bad.tif", "image/tiff") }

    it "stores an error message on the fileset" do
      expect { derivative_service.new(id: valid_change_set.id).create_derivatives }.to raise_error(MiniMagick::Invalid)
      file_set = query_service.find_all_of_model(model: FileSet).first
      expect(file_set.original_file.error_message).to include(/bad magic number/)
    end
  end
end
