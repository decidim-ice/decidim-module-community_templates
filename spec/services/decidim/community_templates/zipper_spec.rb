# frozen_string_literal: true

require "spec_helper"
require "zip"

RSpec.describe Decidim::CommunityTemplates::Zipper do
  let(:fixtures_path) { "spec/fixtures/zipper_test" }
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
      "zipper_test/template.json",
      "zipper_test/data.json",
      "zipper_test/demo.json",
      "zipper_test/assets/city.jpeg"
    )
  end

  it "preserves the directory structure inside the zip" do
    zipper.zip!
    Zip::File.open(zipper.zipfile.path) do |zip_file|
      expect(zip_file.find_entry("zipper_test/template.json")).not_to be_nil
      expect(zip_file.find_entry("zipper_test/data.json")).not_to be_nil
      expect(zip_file.find_entry("zipper_test/demo.json")).not_to be_nil
      expect(zip_file.find_entry("zipper_test/assets/city.jpeg")).not_to be_nil
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
      expect(File).to exist(File.join(destination, "zipper_test/template.json"))
      expect(File).to exist(File.join(destination, "zipper_test/data.json"))
      expect(File).to exist(File.join(destination, "zipper_test/demo.json"))
      expect(File).to exist(File.join(destination, "zipper_test/assets/city.jpeg"))
    end

    it "preserves the directory structure when extracting" do
      zipper.zip!
      described_class.extract_to(zipper.zipfile.path, destination)
      expect(Dir.exist?(File.join(destination, "zipper_test/assets"))).to be true
    end
  end
end
