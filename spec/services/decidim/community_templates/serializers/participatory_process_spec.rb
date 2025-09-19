# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Serializers
      describe ParticipatoryProcess do
        let(:model) { create(:participatory_process, :with_steps) }
        let(:serializer) { described_class.new(model:, metadata:, locales:) }
        let(:metadata) { { name:, description:, version: "1.2.3" } }
        let(:name) do
          {
            "en" => "Participatory process example",
            "ca" => "Exemple de procés participatiu"
          }
        end
        let(:description) do
          {
            "en" => "This is an example participatory process",
            "ca" => "Aquest és un exemple de procés participatiu"
          }
        end
        let(:locales) { %w(en ca) }
        let(:serialized_data) { serializer.serialize }
        let(:data) { serialized_data[:data] }
        let(:demo) { serialized_data[:demo] }
        let(:attributes) { data[:attributes] }
        let(:assets) { serializer.assets }

        it "generates a unique id" do
          expect(serializer.id).to match(/\A[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}\z/)
        end

        it "has the correct metadata" do
          expect(data[:id]).to eq(serializer.id)
          expect(data[:class]).to eq("Decidim::ParticipatoryProcess")
          expect(data[:original_id]).to eq(model.id)
          expect(data[:name]).to eq("#{serializer.id}.metadata.name")
          expect(data[:description]).to eq("#{serializer.id}.metadata.description")
          expect(data[:decidim_version]).to eq(Decidim.version)
          expect(data[:community_templates_version]).to eq(Decidim::CommunityTemplates::VERSION)
          expect(data[:version]).to eq("1.2.3")
        end

        it "has the correct attributes" do
          expect(attributes[:title]).to eq("#{serializer.id}.attributes.title")
          expect(attributes[:description]).to eq("#{serializer.id}.attributes.description")
        end

        it "generates translations" do
          serializer.serialize
          ca = serializer.translations["ca"][serializer.id]["attributes"]
          en = serializer.translations["en"][serializer.id]["attributes"]
          expect(ca["title"]).to eq(model.title["ca"])
          expect(en["title"]).to eq(model.title["en"])
          expect(ca["description"]).to eq(model.description["ca"])
          expect(en["description"]).to eq(model.description["en"])
        end

        it "saves the serialized data to disk" do
          Dir.mktmpdir do |dir|
            expect { serializer.save!(dir) }.not_to raise_error

            base_path = File.join(dir, serializer.id)
            expect(File).to exist(File.join(base_path, "data.json"))
            expect(File).to exist(File.join(base_path, "demo.json"))

            data_content = JSON.parse(File.read(File.join(base_path, "data.json")), symbolize_names: true)
            expect(data_content).to eq(data)

            demo_content = JSON.parse(File.read(File.join(base_path, "demo.json")), symbolize_names: true)
            expect(demo_content).to eq(demo)

            serializer.translations.each_key do |lang|
              lang_file = File.join(base_path, "locales", "#{lang}.yml")
              expect(File).to exist(lang_file)
              lang_content = YAML.load_file(lang_file)[lang]

              expect(lang_content[serializer.id]).to eq(serializer.translations[lang][serializer.id])
            end
          end
        end
      end
    end
  end
end
