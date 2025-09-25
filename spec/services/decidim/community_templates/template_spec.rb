# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe Template do
      let(:template) { create(:template) }
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

      it "is invalid if title is empty" do
        template.title = ""
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(/Title cannot be blank/))
      end

      it "is invalid if short_description is empty" do
        template.short_description = ""
        expect(template).to be_invalid
        expect(template.errors.full_messages).to include(match(/Short description cannot be blank/))
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

      describe "#delete" do
        let(:catalog_path) { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.uuid}") }
        let(:template) { create(:template, owned: true) }
        let(:template_path) { catalog_path.join(template.id) }

        before do
          template.write(catalog_path)
        end

        it "does not delete the template if it is in use" do
          create(:community_template_source, template_id: template.id)
          template.delete(catalog_path)
          expect(template).to be_valid
        end

        it "deletes the template if it is not in use" do
          template.delete(catalog_path)
          expect(template_path.join("manifest.json")).not_to exist
        end

        it "does not delete the template if it is not owned" do
          template.owned = false
          template.delete(catalog_path)
          expect(template_path.join("manifest.json")).to exist
        end
      end

      describe "#write" do
        let(:catalog_path) { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.uuid}") }
        let(:template) { create(:template, owned: true) }
        let(:template_path) { catalog_path.join(template.id) }

        it "writes a manifest.json file the template to the catalog_path" do
          template.write(catalog_path)
          expect(template_path.join("manifest.json")).to exist
        end

        it "do nothing if the template is not owned" do
          template.owned = false
          template.write(catalog_path)
          expect(template_path.join("manifest.json")).not_to exist
        end

        it "does not write owned attribute" do
          template.write(catalog_path)
          expect(template_path.join("manifest.json").read).not_to include("owned")
        end
      end

      describe "#as_json" do
        it "does not include owned attribute" do
          expect(template.as_json).not_to include("owned")
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
        let(:catalog_path) { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.uuid}") }
        let(:template) { create(:template, owned: true) }

        before do
          template.write(catalog_path)
        end

        it "raises an error if the manifest.json is malformatted" do
          expect { Template.from_path(fixtures_path.join("malformatted")) }.to raise_error(JSON::ParserError)
        end

        it "ignores extra fields" do
          loaded_template = Template.from_path(fixtures_path.join("extra_fields"))
          expect(loaded_template.attributes.keys).not_to include("extra_field")
          expect(loaded_template).to be_valid
        end

        it "raises an error if the id is invalid" do
          expect { Template.from_path(fixtures_path.join("invalid_id")) }.to raise_error(ActiveModel::ValidationError).with_message(match(/Id is invalid/))
        end

        it "loads the template from the path" do
          loaded_template = Template.from_path(catalog_path.join(template.id))
          expect(loaded_template.id).to eq(template.id)
          expect(loaded_template.title).to eq(template.title)
        end

        it "defined owned if this server has a template source for the template" do
          create(:community_template_source, template_id: template.id)
          loaded_template = Template.from_path(catalog_path.join(template.id))
          expect(loaded_template.owned).to be_truthy
        end
      end
    end
  end
end
