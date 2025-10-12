# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Importers
      RSpec.describe ParticipatoryProcess, type: :service do
        let(:organization) { create(:organization, available_locales: [:en, :ca, :"pt-BR"]) }
        let(:user) { create(:user, organization: organization) }
        let(:parser) do
          TemplateExtractor.init(
            template_path: "spec/fixtures/template_test/valid",
            locales: organization.available_locales
          ).parser
        end

        subject(:importer) { described_class.new(parser, organization, user) }

        describe "#locales" do
          it "returns the organization's available locales" do
            expect(importer.locales).to eq(%w(en ca pt-BR))
          end
        end

        describe "#required" do
          it "raises an error if the value is blank" do
            expect { importer.required!(:name, nil) }.to raise_error(RuntimeError, /name is required/)
          end

          it "raises an error if the value is empty" do
            expect { importer.required!(:name, "") }.to raise_error(RuntimeError, /name is required/)
          end

          it "raises an error if the value is an empty array" do
            expect { importer.required!(:name, []) }.to raise_error(RuntimeError, /name is required/)
          end

          it "raises an error if the value is an empty hash" do
            expect { importer.required!(:name, {}) }.to raise_error(RuntimeError, /name is required/)
          end

          it "returns the value if it is present" do
            expect(importer.required!(:name, "Name")).to eq("Name")
          end

          it "returns the value if it is an non-empty array" do
            expect(importer.required!(:name, ["Name"])).to eq(["Name"])
          end
        end

        describe "#slugify" do
          it "parameterizes the given text" do
            expect(importer.slugify("Test Process")).to eq("test-process")
          end

          it "appends a number if the slug already exists" do
            create(:participatory_process, slug: "test-process", organization: organization)
            allow(parser).to receive(:model_class).and_return(Decidim::ParticipatoryProcess)
            expect(importer.slugify("Test Process")).to eq("test-process-2")
          end
        end

        describe "#import!" do
          let!(:participatory_process) { importer.import! }

          it "creates a new participatory process with the parsed title and subtitle" do
            expect(participatory_process).to be_persisted
            expect(participatory_process.title).to eq({ "ca" => "Títol del procés participatiu", "en" => "Participatory process title", "pt-BR" => "Título do processo participativo" })
            expect(participatory_process.subtitle).to eq({ "en" => "Participatory process subtitle", "ca" => "Subtítol del procés participatiu", "pt-BR" => "Subtítulo do processo participativo" })
          end

          it "creates a new participatory process with the parsed description and short description" do
            expect(participatory_process.short_description).to eq({ "en" => "Participatory process short description", "ca" => "Descripció breu del procés participatiu", "pt-BR" => "Descrição curta do processo participativo" })
            expect(participatory_process.description).to eq({ "en" => "Participatory process description", "ca" => "Descripció del procés participatiu", "pt-BR" => "Descrição do processo participativo" })
          end

          it "creates a new participatory process with the parsed slug" do
            expect(participatory_process.slug).to eq("participatory-process-title")
          end

          it "creates a new participatory process with the given organization" do
            expect(participatory_process.organization).to eq(organization)
          end

          it "creates a new participatory process with the parsed hero image" do
            participatory_process.reload
            expect(participatory_process.hero_image).to be_attached
            expect(participatory_process.hero_image.attachment.filename.to_s).to eq("image_checksum.jpg")
          end

          it "creates a new participatory process with the parsed hero block" do
            hero_block = Decidim::ContentBlock.where(scope_name: "participatory_process_homepage", manifest_name: "hero", scoped_resource_id: participatory_process.id).first

            expect(hero_block).to be_persisted
            expect(hero_block.scope_name).to eq("participatory_process_homepage")
            expect(hero_block.manifest_name).to eq("hero")
            expect(hero_block.weight).to eq(1)
            expect(hero_block.images_container.background_image).to be_attached
            expect(hero_block.images_container.background_image.attachment.filename.to_s).to eq("image_checksum_content_block.jpg")
          end
        end
      end
    end
  end
end
