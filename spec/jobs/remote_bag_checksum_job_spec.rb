# frozen_string_literal: true

require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe RemoteBagChecksumJob do
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
  let(:file_set) { scanned_resource.decorate.file_sets.first }
  let(:bag_storage_adapter) { Valkyrie::StorageAdapter.find(:bags) }
  let(:bag_exporter) do
    Bagit::BagExporter.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:bags),
      storage_adapter: bag_storage_adapter,
      query_service: Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    )
  end
  let(:resource_bag_adapter) { bag_storage_adapter.for(bag_id: scanned_resource.id) }
  let(:local_file) { resource_bag_adapter.storage_adapter }
  let(:local_bag_path) { "#{local_file.bag_path}.zip" }
  let(:md5_hash) { Digest::MD5.file(local_bag_path).base64digest }
  let(:crc32c) { Digest::CRC32c.file(local_bag_path).base64digest }

  before do
    Figgy.config["google_cloud_storage"]["credentials"]["private_key"] = OpenSSL::PKey::RSA.new(2048).to_s
    bag_exporter.export(resource: scanned_resource)
  end

  context "when compressing into a ZIP file" do
    let(:local_bag_path) { "#{local_file.bag_path}.zip" }

    before do
      RemoteBagChecksumService::ZipCompressedBag.build(path: local_file.bag_path)
      stub_google_cloud_resource(id: scanned_resource.id, md5_hash: md5_hash, crc32c: crc32c, local_file_path: local_bag_path)
      Figgy.config["google_cloud_storage"]["bags"]["format"] = "application/zip"
    end

    describe ".perform_now" do
      it "generates the checksum and appends it to the resource", rabbit_stubbed: true do
        described_class.perform_now(scanned_resource.id.to_s)
        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.id)

        expect(reloaded.remote_checksum).not_to be_empty
        expect(reloaded.remote_checksum).to eq [md5_hash]
      end

      context "when calculating the checksum locally" do
        before do
          allow(Tempfile).to receive(:new).and_call_original
        end

        it "generates the checksum from a locally downloaded file" do
          described_class.perform_now(scanned_resource.id.to_s, local_checksum: true)
          reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.id)

          expect(reloaded.remote_checksum).not_to be_empty
          expect(reloaded.remote_checksum).to eq [md5_hash]
          expect(Tempfile).to have_received(:new).with(scanned_resource.id.to_s)
        end
      end
    end
  end

  context "when calculating the checksum for an uncompressed bag" do
    describe ".perform_now" do
      it "generates the checksum and appends it to the resource", rabbit_stubbed: true do
        described_class.perform_now(scanned_resource.id.to_s, compress_bag: false)
        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.id)

        expect(reloaded.decorate.bag_file_sets.length).to eq 10
        bag_file_set = reloaded.decorate.bag_file_sets.first

        expect(bag_file_set.file_metadata.first.file_identifiers).not_to be_empty
        expect(bag_file_set.file_metadata.first.file_identifiers.first.to_s).to include("https://www.googleapis.com/storage/v1/b/project-figgy-bucket/o/")
      end
    end
  end

  context "when compressing into a TAR file" do
    let(:local_bag_path) { "#{local_file.bag_path}.tgz" }

    before do
      RemoteBagChecksumService::TarCompressedBag.build(path: local_file.bag_path)
      stub_google_cloud_resource(id: scanned_resource.id, md5_hash: md5_hash, crc32c: crc32c, local_file_path: local_bag_path)
    end

    describe ".perform_now" do
      it "generates the checksum and appends it to the resource", rabbit_stubbed: true do
        described_class.perform_now(scanned_resource.id.to_s)
        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.id)

        expect(reloaded.remote_checksum).not_to be_empty
        expect(reloaded.remote_checksum).to eq [md5_hash]
      end

      context "when calculating the checksum locally" do
        before do
          allow(Tempfile).to receive(:new).and_call_original
        end

        it "generates the checksum from a locally downloaded file" do
          described_class.perform_now(scanned_resource.id.to_s, local_checksum: true)
          reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.id)

          expect(reloaded.remote_checksum).not_to be_empty
          expect(reloaded.remote_checksum).to eq [md5_hash]
          expect(Tempfile).to have_received(:new).with(scanned_resource.id.to_s)
        end
      end
    end
  end
end
