# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe TemplateParser do
      let(:locales) { %w(en ca) }
      let(:parser) { described_class.new(data:, translations:, locales:, assets:) }
      let(:data) do
        {
          "id" => "853330aa-0771-4218-8afe-1b199676fbc2",
          "@class" => "Decidim::ParticipatoryProcess",
          "name" => "853330aa-0771-4218-8afe-1b199676fbc2.metadata.name",
          "description" => "853330aa-0771-4218-8afe-1b199676fbc2.metadata.description",
          "version" => "1.0.0",
          "decidim_version" => "0.30.1",
          "community_templates_version" => "0.0.1",
          "original_id" => 1,
          "attributes" => {
            "title" => "853330aa-0771-4218-8afe-1b199676fbc2.attributes.title",
            "description" => "853330aa-0771-4218-8afe-1b199676fbc2.attributes.description"
          }
        }
      end
      let(:translations) do
        {
          "en" => {
            "853330aa-0771-4218-8afe-1b199676fbc2" => {
              "metadata" => {
                "name" => "Participatory process template",
                "description" => "A template for participatory processes"
              },
              "attributes" => {
                "title" => "Participatory process title",
                "description" => "Participatory process description"
              }
            }
          },
          "ca" => {
            "853330aa-0771-4218-8afe-1b199676fbc2" => {
              "metadata" => {
                "name" => "Plantilla de procés participatiu",
                "description" => "Una plantilla per a processos participatius"
              },
              "attributes" => {
                "title" => "Títol del procés participatiu",
                "description" => "Descripció del procés participatiu"
              }
            }
          }
        }
      end
      let(:metadata) { parser.metadata }
      let(:attributes) { parser.attributes }
      let(:demo) { parser.demo }
      let(:assets) do
        [
          {
            id: "m0nidedltelows9rmtzsz0k5vhziut09",
            "@class": "ActiveStorage::Attachment",
            attributes: {
              content_type: "image/jpeg",
              name: "hero_image",
              record_type: "Decidim::ParticipatoryProcess",
              filename: "m0nidedltelows9rmtzsz0k5vhziut09",
              extension: "jpg"
            }
          }
        ]
      end

      it "returns metadata correctly" do
        expect(metadata).to be_a(Hash)

        expect(metadata["id"]).to eq("853330aa-0771-4218-8afe-1b199676fbc2")
        expect(parser.name).to eq("Participatory process template")
        expect(parser.description).to eq("A template for participatory processes")
        expect(parser.version).to eq("1.0.0")

        expect(metadata["name"]).to eq("853330aa-0771-4218-8afe-1b199676fbc2.metadata.name")
        expect(metadata["description"]).to eq("853330aa-0771-4218-8afe-1b199676fbc2.metadata.description")
        expect(metadata["version"]).to eq("1.0.0")
        expect(metadata["decidim_version"]).to eq("0.30.1")
        expect(metadata["community_templates_version"]).to eq("0.0.1")
        expect(metadata["@class"]).to eq("Decidim::ParticipatoryProcess")
        expect(metadata["original_id"]).to eq(1)
      end

      it "returns the model class correctly" do
        expect(parser.model_class).to eq(Decidim::ParticipatoryProcess)
      end

      it "returns attributes correctly" do
        expect(attributes).to be_a(Hash)

        expect(parser.model_title).to eq("Participatory process title")
        expect(parser.model_description).to eq("Participatory process description")
        expect(attributes["title"]).to eq("853330aa-0771-4218-8afe-1b199676fbc2.attributes.title")
        expect(attributes["description"]).to eq("853330aa-0771-4218-8afe-1b199676fbc2.attributes.description")
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

          expect(metadata["id"]).to eq("853330aa-0771-4218-8afe-1b199676fbc2")
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

      it "returns assets correctly" do
        expect(parser.assets).to be_an(Array)
        expect(parser.assets.first).to be_a(Hash)
        expect(parser.assets.first[:id]).to eq("m0nidedltelows9rmtzsz0k5vhziut09")
      end

      context "when data is nil or empty" do
        let(:data) { nil }

        it "handles nil data gracefully" do
          expect { parser.metadata }.to raise_error(NoMethodError)
          expect { parser.attributes }.to raise_error(NoMethodError)
        end
      end

      context "when data has no attributes" do
        let(:data) do
          {
            "id" => "853330aa-0771-4218-8afe-1b199676fbc2",
            "@class" => "Decidim::ParticipatoryProcess"
          }
        end

        it "returns empty attributes hash" do
          expect(parser.attributes).to eq({})
        end

        it "handles missing model attributes gracefully" do
          expect(parser.model_title).to be_nil
          expect(parser.model_description).to be_nil
        end
      end

      context "when @class is invalid" do
        let(:data) do
          {
            "id" => "853330aa-0771-4218-8afe-1b199676fbc2",
            "@class" => "NonExistent::Class"
          }
        end

        it "return nil for invalid class" do
          expect(parser.model_class).to be_nil
        end
      end

      context "when @class is nil" do
        let(:data) do
          {
            "id" => "853330aa-0771-4218-8afe-1b199676fbc2",
            "@class" => nil
          }
        end

        it "returns nil for model_class" do
          expect(parser.model_class).to be_nil
        end
      end

      context "when metadata is blank" do
        let(:data) { {} }

        it "returns nil for model_class" do
          expect(parser.model_class).to be_nil
        end
      end

      context "when translations are missing" do
        let(:translations) { {} }

        it "falls back to field keys when translations missing" do
          expect(parser.name).to eq("853330aa-0771-4218-8afe-1b199676fbc2.metadata.name")
          expect(parser.description).to eq("853330aa-0771-4218-8afe-1b199676fbc2.metadata.description")
        end

        it "falls back to field keys for model attributes" do
          expect(parser.model_title).to eq("853330aa-0771-4218-8afe-1b199676fbc2.attributes.title")
          expect(parser.model_description).to eq("853330aa-0771-4218-8afe-1b199676fbc2.attributes.description")
        end
      end

      context "when translations are malformed" do
        let(:translations) do
          {
            "en" => {
              "853330aa-0771-4218-8afe-1b199676fbc2" => {
                "metadata" => {
                  "name" => nil,
                  "description" => ""
                }
              }
            }
          }
        end

        it "handles nil and empty translations" do
          expect(parser.name).to eq("853330aa-0771-4218-8afe-1b199676fbc2.metadata.name")
          expect(parser.description).to eq("853330aa-0771-4218-8afe-1b199676fbc2.metadata.description")
        end
      end

      context "when field is not a string" do
        let(:data) do
          {
            "id" => "853330aa-0771-4218-8afe-1b199676fbc2",
            "@class" => "Decidim::ParticipatoryProcess",
            "name" => 123,
            "description" => nil,
            "attributes" => {
              "title" => %w(array value),
              "description" => { "hash" => "value" }
            }
          }
        end

        it "handles non-string field values" do
          expect(parser.name).to eq(123.to_s)
          expect(parser.description).to be_nil
          expect(parser.model_title).to eq(%w(array value))
          expect(parser.model_description).to eq({ "hash" => "value" })
        end
      end

      context "when locales array is empty" do
        let(:locales) { [] }

        it "handles empty locales gracefully" do
          expect(parser.name).to eq("853330aa-0771-4218-8afe-1b199676fbc2.metadata.name")
          expect(parser.model_title).to eq("853330aa-0771-4218-8afe-1b199676fbc2.attributes.title")
        end
      end

      context "when field path is malformed" do
        let(:data) do
          {
            "id" => "853330aa-0771-4218-8afe-1b199676fbc2",
            "@class" => "Decidim::ParticipatoryProcess",
            "attributes" => {
              "title" => "853330aa-0771-4218-8afe-1b199676fbc2.attributes.title"
            }
          }
        end
        let(:translations) do
          {
            "en" => {
              "853330aa-0771-4218-8afe-1b199676fbc2" => {
                "attributes" => {
                  "title" => "Translated title"
                }
              }
            }
          }
        end

        it "handles malformed field paths in translations" do
          expect(parser.model_title).to eq("Translated title")
        end
      end

      context "when calling non-existent model methods" do
        it "raises NoMethodError for undefined model methods" do
          expect { parser.model_nonexistent_field }.to raise_error(NoMethodError)
        end

        it "responds correctly to respond_to_missing?" do
          expect(parser.respond_to?(:model_title)).to be true
          expect(parser.respond_to?(:model_description)).to be true
          expect(parser.respond_to?(:model_nonexistent)).to be false
        end
      end

      context "when all_translations_for receives invalid locales" do
        it "handles nil locales gracefully" do
          expect { parser.all_translations_for("field", nil) }.to raise_error(NoMethodError)
        end

        it "handles non-array locales" do
          expect { parser.all_translations_for("field", "en") }.to raise_error(NoMethodError)
        end
      end

      context "when translation_for receives non-string field" do
        it "returns the field as-is for non-string values" do
          expect(parser.translation_for(123)).to eq(123)
          expect(parser.translation_for(nil)).to be_nil
          expect(parser.translation_for({})).to eq({})
        end
      end
    end
  end
end
