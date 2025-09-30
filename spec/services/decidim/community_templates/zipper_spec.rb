# frozen_string_literal: true

require "spec_helper"
require "zip"

RSpec.describe Decidim::CommunityTemplates::Zipper do
  let(:fixtures_path) { "spec/fixtures/template_test/valid" }
  let(:zipper) { described_class.new(path: fixtures_path.to_s) }
  let(:zip_path) do
    zipper.zipfile&.path || begin
      zipper.zip
      zipper.zipfile.path
    end
  end

  after do
    zipper.zipfile&.close!
  end

  it "creates a zip file with the correct pathnames inside" do
    zipper.zip!
    entries = []
    Zip::File.open(zipper.zipfile.path) do |zip_file|
      entries = zip_file.map(&:name)
    end
    expect(entries).to include(
      "valid/data.json",
      "valid/demo.json",
      "valid/assets/city.jpeg"
    )
  end

  it "preserves the directory structure inside the zip" do
    zipper.zip!
    Zip::File.open(zipper.zipfile.path) do |zip_file|
      expect(zip_file.find_entry("valid/data.json")).not_to be_nil
      expect(zip_file.find_entry("valid/demo.json")).not_to be_nil
      expect(zip_file.find_entry("valid/assets/city.jpeg")).not_to be_nil
    end
  end

  describe "#extract_to" do
    let(:destination) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(destination)
    end

    it "extracts the zip contents to the given directory" do
      zipper.zip!
      described_class.extract_to(zipper.zipfile.path, destination)
      expect(File).to exist(File.join(destination, "valid/data.json"))
      expect(File).to exist(File.join(destination, "valid/demo.json"))
      expect(File).to exist(File.join(destination, "valid/assets/city.jpeg"))
    end

    it "preserves the directory structure when extracting" do
      zipper.zip!
      described_class.extract_to(zipper.zipfile.path, destination)
      expect(Dir.exist?(File.join(destination, "valid/assets"))).to be true
    end
  end
end
