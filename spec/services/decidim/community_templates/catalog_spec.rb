# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe Catalog do
      let(:catalog) { create(:catalog, templates: create_list(:template, 1, :owned)) }
      let(:fixtures_path) { Engine.root.join("spec/fixtures/catalog_test") }

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

      describe "#write" do
        let(:catalog_path) { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.uuid}") }

        it "validates before writing" do
          allow(catalog).to receive(:valid?).and_return(true)
          catalog.write(catalog_path)
          expect(catalog).to have_received(:valid?)
        end

        it "writes owned templates to the catalog path" do
          catalog.templates = create_list(:template, 3, :owned)
          catalog.write(catalog_path)
          expect(catalog_path.children.select(&:directory?).size).to eq(3)
        end

        it "does not write owned templates to the catalog path" do
          catalog.templates = create_list(:template, 3, owned: false)
          catalog.write(catalog_path)
          expect(catalog_path.children.select(&:directory?).size).to eq(0)
        end
      end

      describe "#active_templates" do
        it "returns the not archived templates" do
          catalog = create(:catalog, templates: create_list(:template, 3, :owned) + create_list(:template, 1, :archived))
          expect(catalog.active_templates.size).to eq(3)
        end
      end

      describe "#from_path" do
        let(:catalog_path) { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.uuid}") }
        let(:catalog) { create(:catalog, templates: create_list(:template, 3, :owned)) }

        before do
          catalog.write(catalog_path)
        end

        it "loads the catalog from the fixtures" do
          loaded_catalog = Catalog.from_path(fixtures_path.join("valid"))
          expect(loaded_catalog.templates.size).to eq(2)
          expect(loaded_catalog.templates.map(&:title)).to contain_exactly("Idea Board Template", "Participatory Budget Template")
        end

        it "loads available templates" do
          loaded_catalog = Catalog.from_path(catalog_path)
          expect(loaded_catalog.templates.size).to eq(catalog.templates.size)
        end

        it "does not load folder that are not templates" do
          FileUtils.mkdir_p(catalog_path.join("not_a_template"))
          FileUtils.touch(catalog_path.join("not_a_template", "manifest.json"))
          loaded_catalog = Catalog.from_path(catalog_path)
          expect(loaded_catalog.templates.size).to eq(catalog.templates.size)
        end

        it "call Template.from_path for each template" do
          valid_fixtures_path = fixtures_path.join("valid")
          allow(Template).to receive(:from_path).and_call_original
          Catalog.from_path(valid_fixtures_path)
          expect(Template).to have_received(:from_path).with(valid_fixtures_path.join("4aa438f0-cd09-4074-b936-2d4cfce60611"))
          expect(Template).to have_received(:from_path).with(valid_fixtures_path.join("f3c5b62a-f686-4cad-95aa-2041c2c8eb2d"))
        end
      end
    end
  end
end
