# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Serializers
      describe ParticipatoryProcess do
        let(:model) { create(:participatory_process, :with_steps) }
        let(:organization) { model.organization }
        let!(:component) { create(:proposal_component, participatory_space: model) }
        let(:serializer) do
          s = described_class.init(model:, metadata:, locales:, with_manifest:)
          s.metadata_translations!
          s
        end
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

        describe "#assets" do
          it "includes the hero_image" do
            expect(assets.map(&:model)).to include(model.hero_image.attachment)
          end
        end

        it "has the correct metadata" do
          expect(data[:id]).to eq(serializer.id)
          expect(data[:@class]).to eq("Decidim::ParticipatoryProcess")
          expect(data[:name]).to eq("#{serializer.id}.metadata.name")
          expect(data[:description]).to eq("#{serializer.id}.metadata.description")
          expect(data[:decidim_version]).to eq(Decidim.version)
          expect(data[:community_templates_version]).to eq(Decidim::CommunityTemplates::VERSION)
          expect(data[:version]).to eq("1.2.3")
        end

        it "has the correct attributes" do
          expect(attributes[:title]).to eq("#{serializer.id}.attributes.title")
          expect(attributes[:subtitle]).to eq("#{serializer.id}.attributes.subtitle")
          expect(attributes[:slug]).to eq(model.slug)
          expect(attributes[:short_description]).to eq("#{serializer.id}.attributes.short_description")
          expect(attributes[:description]).to eq("#{serializer.id}.attributes.description")
          expect(attributes[:announcement]).to eq("#{serializer.id}.attributes.announcement")
          expect(attributes[:start_date]).to eq(model.start_date.iso8601)
          expect(attributes[:end_date]).to eq(model.end_date.iso8601)
          expect(attributes[:developer_group]).to eq("#{serializer.id}.attributes.developer_group")
          expect(attributes[:local_area]).to eq("#{serializer.id}.attributes.local_area")
          expect(attributes[:meta_scope]).to eq("#{serializer.id}.attributes.meta_scope")
          expect(attributes[:target]).to eq("#{serializer.id}.attributes.target")
          expect(attributes[:participatory_scope]).to eq("#{serializer.id}.attributes.participatory_scope")
          expect(attributes[:participatory_structure]).to eq("#{serializer.id}.attributes.participatory_structure")
          expect(attributes[:private_space]).to eq(model.private_space)
          expect(attributes[:promoted]).to eq(model.promoted)
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
          expect(attributes_ca["subtitle"]).to eq(model.subtitle["ca"])
          expect(attributes_en["subtitle"]).to eq(model.subtitle["en"])
          expect(attributes_ca["short_description"]).to eq(model.short_description["ca"])
          expect(attributes_en["short_description"]).to eq(model.short_description["en"])
          expect(attributes_ca["description"]).to eq(model.description["ca"])
          expect(attributes_en["description"]).to eq(model.description["en"])
          expect(attributes_ca["announcement"]).to eq(model.announcement["ca"])
          expect(attributes_en["announcement"]).to eq(model.announcement["en"])
          expect(attributes_ca["developer_group"]).to eq(model.developer_group["ca"])
          expect(attributes_en["developer_group"]).to eq(model.developer_group["en"])
          expect(attributes_ca["local_area"]).to eq(model.local_area["ca"])
          expect(attributes_en["local_area"]).to eq(model.local_area["en"])
          expect(attributes_ca["meta_scope"]).to eq(model.meta_scope["ca"])
          expect(attributes_en["meta_scope"]).to eq(model.meta_scope["en"])
          expect(attributes_ca["target"]).to eq(model.target["ca"])
          expect(attributes_en["target"]).to eq(model.target["en"])
          expect(attributes_ca["participatory_scope"]).to eq(model.participatory_scope["ca"])
          expect(attributes_en["participatory_scope"]).to eq(model.participatory_scope["en"])
          expect(attributes_ca["participatory_structure"]).to eq(model.participatory_structure["ca"])
          expect(attributes_en["participatory_structure"]).to eq(model.participatory_structure["en"])
          expect(attributes_ca["components"]["proposals_#{component.id}"]["attributes"]["name"]).to eq(component.name["ca"])
          expect(attributes_en["components"]["proposals_#{component.id}"]["attributes"]["name"]).to eq(component.name["en"])
        end

        it "includes components" do
          expect(attributes[:components]).to be_an(Array)
          expect(attributes[:components].size).to eq(1)
          component_data = attributes[:components].first
          expect(component_data[:id]).to eq("#{serializer.id}.attributes.components.proposals_#{component.id}")
          expect(component_data[:@class]).to eq("Decidim::Component")
          expect(component_data[:attributes][:name]).to eq("#{serializer.id}.attributes.components.proposals_#{component.id}.attributes.name")
          expect(component_data[:attributes][:manifest_name]).to eq(component.manifest_name)
          expect(component_data[:attributes][:settings]).to be_an(Hash)
        end

        it "includes hero_image" do
          expect(attributes[:hero_image]).to be_an(String)
          expect(attributes[:hero_image]).to eq(Serializers::Attachment.filename(model.hero_image))
        end

        context "with content blocks" do
          let(:image) do
            Rack::Test::UploadedFile.new(
              Decidim::Dev.test_file("city.jpeg", "image/jpeg"),
              "image/jpeg"
            )
          end
          let!(:content_block) do
            block = create(:content_block, organization:, scope_name: :participatory_process_homepage, manifest_name: :hero, scoped_resource_id: model.id)
            block.images_container.background_image = image
            block.save
            block.reload
            block
          end

          it "includes content blocks" do
            expect(attributes[:content_blocks]).to be_an(Array)

            hero_block = attributes[:content_blocks].find { |block| block[:attributes][:manifest_name] == "hero" }
            expect(hero_block).to be_an(Hash)
            expect(hero_block[:id]).to eq("#{serializer.id}.attributes.content_blocks.participatory_process_homepage_#{content_block.id}")
            expect(hero_block[:attributes][:scope_name]).to eq("participatory_process_homepage")
            expect(hero_block[:attributes][:images_container]).to be_an(Hash)
            expect(hero_block[:attributes][:images_container][:background_image]).to be_an(String)
          end
        end

        describe "#save!" do
          it "does not raise an error" do
            Dir.mktmpdir do |dir|
              expect { serializer.save!(dir) }.not_to raise_error
            end
          end

          it "saves the serialized json data to disk" do
            Dir.mktmpdir do |dir|
              serializer.save!(dir)
              base_path = File.join(dir, serializer.id)
              expect(File).to exist(File.join(base_path, "data.json"))
              expect(File).to exist(File.join(base_path, "demo.json"))
            end
          end

          it "saves translations to disk" do
            Dir.mktmpdir do |dir|
              serializer.save!(dir)
              base_path = File.join(dir, serializer.id)
              expect(File).to exist(File.join(base_path, "locales", "en.yml"))
              expect(File).to exist(File.join(base_path, "locales", "ca.yml"))
            end
          end

          it "saves assets to disk" do
            Dir.mktmpdir do |dir|
              serializer.save!(dir)
              base_path = File.join(dir, serializer.id)
              filename = Attachment.filename(model.hero_image)
              expect(File).to exist(File.join(base_path, "assets", filename))
            end
          end

          it "removes unused assets" do
            Dir.mktmpdir do |dir|
              base_path = File.join(dir, serializer.id)
              FileUtils.mkdir_p(File.join(base_path, "assets"))
              File.write(File.join(base_path, "assets", "unused.pdf"), "unused")
              serializer.save!(dir)
              base_path = File.join(dir, serializer.id)
              expect(File).not_to exist(File.join(base_path, "assets", "unused.pdf"))
            end
          end
        end
      end
    end
  end
end
