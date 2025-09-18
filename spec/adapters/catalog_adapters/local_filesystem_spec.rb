# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module CatalogAdapters
      describe LocalFilesystem, type: :model do
        let(:tmp_dir) { Dir.mktmpdir }
        let(:adapter) { described_class.new(path: tmp_dir) }

        after { FileUtils.remove_entry(tmp_dir) }

        describe "#base_path" do
          it "returns the base path from options" do
            expect(adapter.base_path).to eq(tmp_dir)
          end
        end

        describe "#manifest_file" do
          it "returns the path to the manifest.json file" do
            expect(adapter.manifest_file).to eq(File.join(tmp_dir, "manifest.json"))
          end
        end

        describe "#metadata" do
          it "returns nil if manifest file does not exist" do
            expect(adapter.metadata).to be_nil
          end

          it "returns parsed JSON if manifest file exists" do
            File.write(adapter.manifest_file, '{"foo": "bar"}')
            expect(adapter.metadata).to eq({ "foo" => "bar" })
          end
        end
      end
    end
  end
end
