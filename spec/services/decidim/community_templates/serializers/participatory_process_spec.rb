# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Serializers
      describe ParticipatoryProcess do
        let(:model) { create(:participatory_process, :with_steps) }
        let!(:component) { create(:proposal_component, participatory_space: model) }
        let(:serializer) { described_class.init(model:, metadata:, locales:, with_manifest:) }
        let(:metadata) { { name:, description:, version: "1.2.3" } }
        let(:with_manifest) { true }
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
        let(:data) { serializer.data }
        let(:demo) { serializer.demo }
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
          expect(attributes[:subtitle]).to eq("#{serializer.id}.attributes.subtitle")
          expect(attributes[:weight]).to eq(model.weight)
          expect(attributes[:slug]).to eq(model.slug)
          expect(attributes[:short_description]).to eq("#{serializer.id}.attributes.short_description")
          expect(attributes[:description]).to eq("#{serializer.id}.attributes.description")
          expect(attributes[:announcement]).to eq("#{serializer.id}.attributes.announcement")
          expect(attributes[:start_date]).to eq(model.start_date)
          expect(attributes[:end_date]).to eq(model.end_date)
          expect(attributes[:developer_group]).to eq("#{serializer.id}.attributes.developer_group")
          expect(attributes[:local_area]).to eq("#{serializer.id}.attributes.local_area")
          expect(attributes[:meta_scope]).to eq("#{serializer.id}.attributes.meta_scope")
          expect(attributes[:target]).to eq("#{serializer.id}.attributes.target")
          expect(attributes[:participatory_scope]).to eq("#{serializer.id}.attributes.participatory_scope")
          expect(attributes[:participatory_structure]).to eq("#{serializer.id}.attributes.participatory_structure")
        end

        it "generates translations" do
          metadata_ca = serializer.translations["ca"][serializer.id]["metadata"]
          metadata_en = serializer.translations["en"][serializer.id]["metadata"]
          expect(metadata_ca["name"]).to eq(name["ca"])
          expect(metadata_en["name"]).to eq(name["en"])
          expect(metadata_ca["description"]).to eq(description["ca"])
          expect(metadata_en["description"]).to eq(description["en"])

          attributes_ca = serializer.translations["ca"][serializer.id]["attributes"]
          attributes_en = serializer.translations["en"][serializer.id]["attributes"]
          expect(attributes_ca["title"]).to eq(model.title["ca"])
          expect(attributes_en["title"]).to eq(model.title["en"])
          expect(attributes_ca["description"]).to eq(model.description["ca"])
          expect(attributes_en["description"]).to eq(model.description["en"])
          expect(attributes_ca["components"][component.id.to_s]["attributes"]["name"]).to eq(component.name["ca"])
          expect(attributes_en["components"][component.id.to_s]["attributes"]["name"]).to eq(component.name["en"])
        end

        it "includes components" do
          expect(attributes[:components]).to be_an(Array)
          expect(attributes[:components].size).to eq(1)
          component_data = attributes[:components].first
          expect(component_data[:id]).to eq("#{serializer.id}.attributes.components.#{component.id}")
          expect(component_data[:class]).to eq("Decidim::Component")
          expect(component_data[:original_id]).to eq(component.id)
          expect(component_data[:attributes][:name]).to eq("#{serializer.id}.attributes.components.#{component.id}.attributes.name")
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
