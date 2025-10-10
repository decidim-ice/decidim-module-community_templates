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
          it "creates a new participatory process with the parsed title and a unique slug" do
            participatory_process = importer.import!
            expect(participatory_process).to be_persisted
            expect(participatory_process.title).to eq({ "ca" => "Títol del procés participatiu", "en" => "Participatory process title", "pt-BR" => "Título do processo participativo" })
            expect(participatory_process.subtitle).to eq({ "en" => "Participatory process subtitle", "ca" => "Subtítol del procés participatiu", "pt-BR" => "Subtítulo do processo participativo" })
            expect(participatory_process.short_description).to eq({ "en" => "Participatory process short description", "ca" => "Descripció breu del procés participatiu", "pt-BR" => "Descrição curta do processo participativo" })
            expect(participatory_process.description).to eq({ "en" => "Participatory process description", "ca" => "Descripció del procés participatiu", "pt-BR" => "Descrição do processo participativo" })
            expect(participatory_process.slug).to eq("participatory-process-title")
            expect(participatory_process.organization).to eq(organization)
          end
        end
      end
    end
  end
end
