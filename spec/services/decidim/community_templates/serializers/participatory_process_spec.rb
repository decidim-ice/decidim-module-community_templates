# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Serializers
      describe ParticipatoryProcess do
        let(:participatory_process) { create(:participatory_process, :with_steps) }
        let(:serializer) { described_class.new(participatory_process) }
        let(:serialized_data) { serializer.serialize }
        let(:data) { serialized_data[:data] }
        let(:demo) { serialized_data[:demo] }
        let(:attributes) { data[:attributes] }
        let(:assets) { serializer.assets }

        it "generates a unique id" do
          expect(serializer.id).to match(/\A[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}\z/)
        end

        it "has the correct type" do
          expect(data[:class]).to eq("Decidim::ParticipatoryProcess")
          expect(data[:id]).to eq(serializer.id)
          expect(attributes[:title]).to eq("#{serializer.id}.title")
          expect(attributes[:description]).to eq("#{serializer.id}.description")
        end

        it "generates translations" do
          serializer.serialize
          ca = serializer.translations["ca"][serializer.id]
          en = serializer.translations["en"][serializer.id]
          expect(ca["title"]).to eq(participatory_process.title["ca"])
          expect(en["title"]).to eq(participatory_process.title["en"])
          expect(ca["description"]).to eq(participatory_process.description["ca"])
          expect(en["description"]).to eq(participatory_process.description["en"])
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
              lang_content = YAML.load_file(lang_file)
              expect(lang_content[serializer.id]).to eq(serializer.translations[lang][serializer.id])
            end
          end
        end
      end
    end
  end
end
