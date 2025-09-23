# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe TemplateParser do
      let(:template_path) { "spec/fixtures/template_test" }
      let(:locales) { %w(en ca) }
      let(:parser) { described_class.new(template_path, locales) }
      let(:data) { parser.data }
      let(:metadata) { parser.metadata }
      let(:attributes) { parser.attributes }
      let(:demo) { parser.demo }
      let(:assets) { parser.assets }

      it "returns metadata correctly" do
        expect(metadata).to be_a(Hash)

        expect(metadata["id"]).to eq("pp-template-001")
        expect(parser.name).to eq("Participatory process template")
        expect(parser.description).to eq("A template for participatory processes")
        expect(parser.version).to eq("1.0.0")

        expect(metadata["name"]).to eq("pp-template-001.metadata.name")
        expect(metadata["description"]).to eq("pp-template-001.metadata.description")
        expect(metadata["version"]).to eq("1.0.0")
        expect(metadata["decidim_version"]).to eq("0.30.1")
        expect(metadata["community_templates_version"]).to eq("0.0.1")
        expect(metadata["class"]).to eq("Decidim::ParticipatoryProcess")
        expect(metadata["original_id"]).to eq(1)
      end

      it "returns the model class correctly" do
        expect(parser.model_class).to eq(Decidim::ParticipatoryProcess)
      end

      it "returns attributes correctly" do
        expect(attributes).to be_a(Hash)

        expect(parser.model_title).to eq("Participatory process title")
        expect(parser.model_description).to eq("Participatory process description")
        expect(attributes["title"]).to eq("pp-template-001.attributes.title")
        expect(attributes["description"]).to eq("pp-template-001.attributes.description")
      end

      it "returns translations correctly for the model translatable fields" do
        expect(parser.model_title(locales)).to eq({ "en" => "Participatory process title", "ca" => "Títol del procés participatiu" })
        expect(parser.model_description(locales)).to eq({ "en" => "Participatory process description", "ca" => "Descripció del procés participatiu" })

        expect(parser.model_title(["ca"])).to eq({ "ca" => "Títol del procés participatiu" })
        expect(parser.model_title(["en"])).to eq({ "en" => "Participatory process title" })
      end

      context "when locales reversed" do
        let(:locales) { %w(ca en) }

        it "returns metadata correctly" do
          expect(metadata).to be_a(Hash)

          expect(metadata["id"]).to eq("pp-template-001")
          expect(parser.name).to eq("Plantilla de procés participatiu")
          expect(parser.description).to eq("Una plantilla per a processos participatius")
          expect(metadata["version"]).to eq("1.0.0")
        end

        it "returns attributes correctly" do
          expect(attributes).to be_a(Hash)

          expect(parser.model_title).to eq("Títol del procés participatiu")
          expect(parser.model_description).to eq("Descripció del procés participatiu")
        end
      end
    end
  end
end
