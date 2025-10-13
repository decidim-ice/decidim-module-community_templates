# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Importers
      RSpec.describe Attachment, type: :service do
        let(:organization) { create(:organization) }
        let(:user) { create(:user, organization: organization) }
        let(:participatory_process) { create(:participatory_process, organization: organization) }
        let(:parent_object) { OpenStruct.new(object: participatory_process.hero_image) }

        let(:parser) do
          TemplateParser.new(
            data: {
              "id" => "image_checksum",
              "@class" => "ActiveStorage::Attachment",
              "attributes" => {
                "content_type" => "image/jpeg",
                "name" => "hero_image",
                "record_type" => "Decidim::ParticipatoryProcess",
                "filename" => "image_checksum",
                "extension" => "jpg",
                "@local_path" => "spec/fixtures/template_test/valid/assets/image_checksum.jpg"
              }
            },
            assets: [],
            translations: {},
            locales: organization.available_locales.map(&:to_s)
          )
        end

        subject(:importer) { described_class.new(parser, organization, user, parent: parent_object) }

        describe "#import!" do
          before do
            # Create a test image file
            test_image_path = "spec/fixtures/template_test/valid/assets/image_checksum.jpg"
            FileUtils.mkdir_p(File.dirname(test_image_path))
            File.write(test_image_path, "fake image content")
            # Remove any previous hero_image
            participatory_process.reload.hero_image.purge
          end

          after do
            # Clean up test file
            test_image_path = "spec/fixtures/template_test/valid/assets/image_checksum.jpg"
            FileUtils.rm_f(test_image_path)
          end

          context "when parent object is wrong" do
            it "raise an error if parent.object do not respond to attach" do
              parent_object.object = participatory_process
              expect { importer.import! }.to raise_error(RuntimeError, /parent.object do not respond to attach/)
            end

            it "raise an error if parent.object do not respond to attached?" do
              parent_object.object = OpenStruct.new
              allow(parent_object.object).to receive(:attach).and_return(false)
              expect { importer.import! }.to raise_error(RuntimeError, /parent.object do not respond to attached?/)
            end

            it "raise an error if parent.object is nil" do
              parent_object.object = nil
              expect { importer.import! }.to raise_error(RuntimeError, /parent.object is nil/)
            end
          end

          context "when file exists" do
            it "attaches the file to the parent object" do
              expect { importer.import! }.to change { participatory_process.reload.hero_image.attached? }.from(false).to(true)
            end

            it "sets the correct filename" do
              importer.import!
              participatory_process.reload
              expect(participatory_process.hero_image.filename.to_s).to eq("image_checksum.jpg")
            end

            it "returns the blob object" do
              blob = importer.import!
              expect(blob).to be_a(ActiveStorage::Blob)
              expect(blob.filename.to_s).to eq("image_checksum.jpg")
            end

            it "saves the parent object" do
              allow(parent_object.object).to receive(:save)
              importer.import!
              expect(parent_object.object).to have_received(:save)
            end
          end

          context "when file does not exist" do
            before do
              parser.attributes["@local_path"] = "nonexistent/file.jpg"
            end

            it "raises an error" do
              expect { importer.import! }.to raise_error(RuntimeError, %r{File does not exists: nonexistent/file\.jpg})
            end
          end

          context "when @local_path is missing" do
            before do
              parser.attributes.delete("@local_path")
            end

            it "raises an error" do
              expect { importer.import! }.to raise_error(RuntimeError, /@local_path is required/)
            end
          end

          context "when @local_path is blank" do
            before do
              parser.attributes["@local_path"] = ""
            end

            it "raises an error" do
              expect { importer.import! }.to raise_error(RuntimeError, /@local_path is required/)
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
