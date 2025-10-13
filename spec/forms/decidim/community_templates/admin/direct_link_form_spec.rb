# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe DirectLinkForm do
        let(:organization) { create(:organization) }
        let(:user) { create(:user, organization: organization) }
        let(:form) { described_class.new }
        let(:valid_uuid) { "00605f97-a5d6-4464-9c7e-5bc5d5840212" }
        let(:fixture_path) { Decidim::CommunityTemplates::Engine.root.join("spec", "fixtures", "catalog_test", "valid", valid_uuid) }
        let(:valid_data) do
          File.read(fixture_path.join("data.json"))
        end

        before do
          allow(Decidim::CommunityTemplates::HttpTemplateExtractor).to receive(:fetch).and_return(valid_data)
        end

        it "is invalid if the link is not a https:// link" do
          form.link = "http://example.com"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/not looks like a valid template link/)
        end

        it "is invalid if the link does not ends with a valid uuid" do
          form.link = "https://example.com/some-uuid"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/not looks like a valid template link/)
        end

        it "is invalid if link uuid does not match manifest id" do
          form.link = "https://example.com/123e4567-e89b-12d3-a456-426614174000"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/not looks like a valid template link/)
        end

        it "is invalid if the manifest.json is not found" do
          allow(Decidim::CommunityTemplates::HttpTemplateExtractor).to receive(:fetch).and_return(nil)
          form.link = "https://example.com/#{valid_uuid}"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/Manifest file not found/)
        end

        it "is invalid if the @class has not available importer class" do
          allow(Decidim::CommunityTemplates::HttpTemplateExtractor).to receive(:fetch).and_return({
            id: valid_uuid,
            "@class": "Decidim::Initiatives::Initiative",
            name: "Initiative Template",
            description: "Initiative Template",
            version: "1.0.0",
            author: "Initiative Template",
            links: ["https://example.com"],
            community_templates_version: "1.0.0",
            decidim_version: "1.0.0"

          }.to_json)
          form.link = "https://example.com/#{valid_uuid}"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/Importer class is not found/)
        end

        it "is invalid if the fetched template is invalid" do
          allow(Decidim::CommunityTemplates::HttpTemplateExtractor).to receive(:fetch).and_return({
            id: valid_uuid,
            name: "Invalid Template",
            description: "Invalid Template",
            version: "1.0.0",
            author: "Invalid Template",
            links: ["invalid"],
            "@class": "invalid",
            community_templates_version: "1.0.0",
            decidim_version: "1.0.0"
          }.to_json)
          form.link = "https://example.com/#{valid_uuid}"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/Importer class is not found/)
        end

        it "is valid if the link ends with a valid uuid" do
          form.link = "https://example.com/#{valid_uuid}"
          expect(form).to be_valid
        end
      end
    end
  end
end
