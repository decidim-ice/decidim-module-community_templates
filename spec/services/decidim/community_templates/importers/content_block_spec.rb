# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Importers
      RSpec.describe ContentBlock, type: :service do
        let(:organization) { create(:organization) }
        let(:user) { create(:user, organization: organization) }
        let(:participatory_process) { create(:participatory_process, organization: organization) }
        let(:parent_object) { OpenStruct.new(object: participatory_process, organization: organization) }

        let(:parser) do
          TemplateParser.new(
            data: {
              "id" => "content_block_id",
              "@class" => "Decidim::ContentBlock",
              "attributes" => {
                "scope_name" => "participatory_process_homepage",
                "manifest_name" => "hero",
                "weight" => 1,
                "settings" => [
                  {
                    "type" => "text",
                    "value" => "Test content"
                  }
                ],
                "images_container" => {
                  "background_image" => "image_checksum_content_block"
                },
                "published_at_relative" => 172_800
              }
            },
            assets: [
              {
                "id" => "image_checksum_content_block",
                "@class" => "ActiveStorage::Attachment",
                "attributes" => {
                  "content_type" => "image/jpeg",
                  "name" => "file",
                  "record_type" => "Decidim::ContentBlock",
                  "filename" => "image_checksum_content_block",
                  "extension" => "jpg",
                  "@local_path" => "spec/fixtures/template_test/valid/assets/image_checksum_content_block.jpg"
                }
              }
            ],
            translations: {},
            locales: organization.available_locales.map(&:to_s)
          )
        end

        subject(:importer) { described_class.new(parser, organization, user, parent: parent_object) }

        describe "#import!" do
          before do
            # Create a test image file
            test_image_path = "spec/fixtures/template_test/valid/assets/image_checksum_content_block.jpg"
            FileUtils.mkdir_p(File.dirname(test_image_path))
            File.write(test_image_path, "fake image content")
          end

          after do
            # Clean up test file
            test_image_path = "spec/fixtures/template_test/valid/assets/image_checksum_content_block.jpg"
            FileUtils.rm_f(test_image_path)
          end

          context "when parent object is invalid" do
            it "raises an error if parent.object is nil" do
              parent_object.object = nil
              expect { importer.import! }.to raise_error(RuntimeError, /parent.object is nil/)
            end

            it "raises an error if parent.object does not respond to id" do
              parent_object.object = OpenStruct.new
              expect { importer.import! }.to raise_error(RuntimeError, /parent.object do not respond to id/)
            end

            it "raises an error if parent.object is not persisted" do
              parent_object.object = build(:participatory_process, organization: organization)
              expect { importer.import! }.to raise_error(RuntimeError, /parent.object is not persisted/)
            end
          end

          context "when required attributes are missing" do
            it "raises an error if scope_name is missing" do
              parser.attributes.delete("scope_name")
              expect { importer.import! }.to raise_error(RuntimeError, /Value for scope_name is required/)
            end

            it "raises an error if manifest_name is missing" do
              parser.attributes.delete("manifest_name")
              expect { importer.import! }.to raise_error(RuntimeError, /Value for manifest_name is required/)
            end

            it "raises an error if weight is missing" do
              parser.attributes.delete("weight")
              expect { importer.import! }.to raise_error(RuntimeError, /Value for weight is required/)
            end
          end

          context "when content block is created successfully" do
            it "creates a content block with correct attributes" do
              expect { importer.import! }.to change(Decidim::ContentBlock, :count).by(1)

              content_block = Decidim::ContentBlock.last
              expect(content_block.scope_name).to eq("participatory_process_homepage")
              expect(content_block.manifest_name).to eq("hero")
              expect(content_block.weight).to eq(1)
              expect(content_block.scoped_resource_id).to eq(participatory_process.id)
              expect(content_block.organization).to eq(organization)
            end

            it "sets published_at when provided" do
              importer.import!
              content_block = Decidim::ContentBlock.last
              expect(content_block.published_at).to be_present
            end

            it "sets published_at to nil when not provided" do
              parser.attributes.delete("published_at_relative")
              importer.import!
              content_block = Decidim::ContentBlock.last
              expect(content_block.published_at).to be_nil
            end

            it "sets settings when provided" do
              importer.import!
              content_block = Decidim::ContentBlock.last
              expect(content_block.settings).to be_present
            end

            it "returns the created content block" do
              result = importer.import!
              expect(result).to be_a(Decidim::ContentBlock)
              expect(result.scope_name).to eq("participatory_process_homepage")
            end
          end

          context "when importing images container" do
            it "creates content block attachment for background image" do
              expect { importer.import! }.to change(Decidim::ContentBlockAttachment, :count).by(1)

              content_block = Decidim::ContentBlock.last
              attachment = Decidim::ContentBlockAttachment.last
              expect(attachment.content_block).to eq(content_block)
              expect(attachment.name).to eq("background_image")
            end

            it "attaches the image file" do
              importer.import!
              importer.after_import!

              content_block = Decidim::ContentBlock.last
              expect(content_block.images_container.background_image).to be_attached
              expect(content_block.images_container.background_image.filename.to_s).to eq("image_checksum_content_block.jpg")
            end

            it "handles missing asset gracefully" do
              parser.assets.clear
              expect { importer.import! }.not_to raise_error

              content_block = Decidim::ContentBlock.last
              expect(content_block.images_container.background_image).not_to be_attached
            end
          end
        end

        describe "inherited methods from ImporterBase" do
          it "has access to parser" do
            expect(importer.parser).to eq(parser)
          end

          it "has access to organization" do
            expect(importer.organization).to eq(organization)
          end

          it "has access to user" do
            expect(importer.user).to eq(user)
          end

          it "has access to parent" do
            expect(importer.parent).to eq(parent_object)
          end
        end
      end
    end
  end
end
