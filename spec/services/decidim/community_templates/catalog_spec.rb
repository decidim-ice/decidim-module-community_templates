# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe Catalog do
      let(:organization) { create(:organization) }
      let(:catalog) { create(:catalog, templates: create_list(:template_metadata, 1, organization:)) }

      before do
        allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return(Pathname.new(Dir.mktmpdir))
      end

      it "is valid with all attributes defined" do
        expect(catalog).to be_valid
      end

      it "is invalid if templates are not an array of templates" do
        catalog.templates = ["not a template"]
        expect(catalog).to be_invalid
        expect(catalog.errors.full_messages).to include(match(/Templates are invalid/))
      end

      it "is invalid if templates is not an array" do
        catalog.templates = 4562
        expect(catalog).to be_invalid
        expect(catalog.errors.full_messages).to include(match(/Templates are invalid/))
      end

      it "is valid if templates are empty" do
        catalog.templates = []
        expect(catalog).to be_valid
      end

      describe "#active_templates" do
        it "returns the not archived templates" do
          catalog = create(:catalog, templates: create_list(:template_metadata, 3) + create_list(:template_metadata, 1, :archived))
          expect(catalog.active_templates.size).to eq(3)
        end
      end

      describe "#from_path" do
        let(:catalog_path) { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.uuid}") }
        let(:catalog) { create(:catalog, templates: create_list(:template_metadata, 3, organization:)) }
        let(:fixtures_path) { Decidim::CommunityTemplates::Engine.root.join("spec/fixtures/catalog_test/valid") }

        before do
          Decidim::CommunityTemplates.catalog_dir = catalog_path
          FileUtils.mkdir_p(Rails.root.join("tmp/catalogs"))

          FileUtils.rm_rf(catalog_path)
          FileUtils.cp_r(fixtures_path, catalog_path)
        end

        it "loads available templates" do
          expect(catalog.templates.size).to eq(3)
        end

        it "does not load folder that are not templates" do
          FileUtils.mkdir_p(catalog_path.join("not_a_template"))
          FileUtils.touch(catalog_path.join("not_a_template", "data.json"))
          loaded_catalog = Catalog.from_path(catalog_path)
          expect(catalog_path.children.size).to eq(2)
          expect(loaded_catalog.templates.size).to eq(1)
        end

        it "call TemplateExtractor.parse for each template" do
          allow(TemplateExtractor).to receive(:parse).and_call_original
          Catalog.from_path(fixtures_path)
          expect(TemplateExtractor).to have_received(:parse).with(fixtures_path.join("00605f97-a5d6-4464-9c7e-5bc5d5840212"))
        end
      end
    end
  end
end
