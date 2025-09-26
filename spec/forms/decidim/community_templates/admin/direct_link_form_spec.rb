# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe DirectLinkForm do
        let(:organization) { create(:organization) }
        let(:user) { create(:user, organization: organization) }
        let(:form) { described_class.new }
        let(:valid_uuid) { "4aa438f0-cd09-4074-b936-2d4cfce60611" }
        let(:fixture_path) { Decidim::CommunityTemplates::Engine.root.join("spec", "fixtures", "catalog_test", "valid", valid_uuid) }
        let(:valid_manifest) do
          File.read(fixture_path.join("manifest.json"))
        end

        before do
          allow(Net::HTTP).to receive(:get_response).and_return(double(code: "200", body: valid_manifest))
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
          allow(Net::HTTP).to receive(:get_response).and_return(double(code: "404", body: ""))
          form.link = "https://example.com/#{valid_uuid}"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/Manifest file not found/)
        end

        it "is invalid if the manifest.json redirects" do
          allow(Net::HTTP).to receive(:get_response).and_return(double(code: "302", body: ""))
          form.link = "https://example.com/#{valid_uuid}"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/Manifest file not found/)
        end

        it "is invalid if the fetched template is invalid" do
          allow(Net::HTTP).to receive(:get_response).and_return(double(code: "200", body: {
            id: valid_uuid,
            title: "Invalid Template",
            short_description: "Invalid Template",
            version: "1.0.0",
            author: "Invalid Template",
            links: ["invalid"],
            source_type: "invalid",
            community_template_version: "1.0.0",
            decidim_version: "1.0.0"
          }.to_json))
          form.link = "https://example.com/#{valid_uuid}"
          expect(form).to be_invalid
          expect(form.errors.full_messages).to include(/Source type is not included in the list/)
        end

        it "is valid if the link ends with a valid uuid" do
          form.link = "https://example.com/#{valid_uuid}"
          expect(form).to be_valid
        end
      end
    end
  end
end
