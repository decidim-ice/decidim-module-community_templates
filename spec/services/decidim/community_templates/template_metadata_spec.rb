# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe TemplateMetadata do
      let(:template) { create(:template_metadata) }
      let(:fixtures_path) { Engine.root.join("spec/fixtures/template_test") }

      it "is valid with all attributes defined" do
        expect(template).to be_valid
      end

      it "is invalid if id is empty" do
        template.id = ""
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(/Id cannot be blank/))
      end

      it "is invalid if id is not a valid UUID" do
        template.id = "invalid_id"
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(/Id is invalid/))
      end

      it "is invalid if name is empty" do
        template.name = ""
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(/Name cannot be blank/))
      end

      it "is invalid if description is empty" do
        template.description = ""
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(/Description cannot be blank/))
      end

      it "is invalid if version is empty" do
        template.version = ""
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(/Version cannot be blank/))
      end

      it "is invalid if author is empty" do
        template.author = ""
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(/Author cannot be blank/))
      end

      it "is valid if links is empty" do
        template.links = []
        expect(template).to be_valid
      end

      it "is invalid if links is not an array of https links" do
        template.links = ["http://example.com"]
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(%r{must be valid links starting with https://}))
      end

      it "is valid if links is an array of https links" do
        template.links = ["https://example.com"]
        expect(template).to be_valid
      end

      it "is invalid if links is an array of invalid https links" do
        template.links = ["https://"]
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(%r{must be valid links starting with https://}))
      end

      describe "#public_url" do
        it "returns the public url of the template" do
          expect(template.public_url("example.com")).to eq("https://example.com/catalog/#{template.id}")
        end
      end

      describe "#normalized_links" do
        it "removes duplicates" do
          template.links = ["https://duplicated.com", "https://duplicated.com/"]
          expect(template.normalized_links).to eq(["https://duplicated.com"])
        end

        it "removes trailing slashes" do
          template.links = ["https://example.com/"]
          expect(template.normalized_links).to eq(["https://example.com"])
        end

        it "extract csv links" do
          template.links = ["https://example.com/,https://new.com"]
          expect(template.normalized_links).to eq(["https://example.com", "https://new.com"])
        end

        it "strips spaces" do
          template.links = [" https://example.com ", "  https://new.com  , https://example2.com/  "]
          expect(template.normalized_links).to eq(["https://example.com", "https://new.com", "https://example2.com"])
        end
      end

      describe "#as_json" do
        it "normalize links" do
          template.links = ["https://example.com/", "https://duplicated.com", "https://duplicated.com/", "https://duplicated.com/", "https://example.com/,   https://new.com/"]

          expect(template.as_json).to include("links" => ["https://example.com", "https://duplicated.com", "https://new.com"])
        end
      end

      describe "#to_json" do
        it "calls #as_json" do
          allow(template).to receive(:as_json).and_call_original
          template.to_json
          expect(template).to have_received(:as_json)
          expect(template.to_json).to eq(template.as_json.to_json)
        end
      end

      describe "#from_path" do
        let(:catalog_path) do
          catalog_path = Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.uuid}")
          Decidim::CommunityTemplates.catalog_dir = catalog_path
          catalog_path
        end
        let(:template) { create(:template_metadata) }

        it "raises an error if the manifest.json is malformatted" do
          expect { TemplateMetadata.from_path(fixtures_path.join("malformatted")) }.to raise_error(ActiveModel::ValidationError)
        end

        it "ignores extra fields" do
          loaded_template = TemplateMetadata.from_path(fixtures_path.join("extra_fields"))
          expect(loaded_template.attributes.keys).not_to include("extra_field")
          expect(loaded_template).to be_valid
        end

        it "raises an error if the id is invalid" do
          expect { TemplateMetadata.from_path(fixtures_path.join("invalid_id")) }.to raise_error(ActiveModel::ValidationError).with_message(match(/Id is invalid/))
        end

        it "loads the template from the path" do
          loaded_template = TemplateMetadata.from_path(catalog_path.join(template.id))
          expect(loaded_template.id).to eq(template.id)
          expect(loaded_template.name).to eq(template.name)
        end
      end
    end
  end
end
