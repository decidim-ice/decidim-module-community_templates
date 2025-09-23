# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Importers
      RSpec.describe ParticipatoryProcess, type: :service do
        let(:organization) { create(:organization, available_locales: [:en, :ca]) }
        let(:user) { create(:user, organization: organization) }
        let(:parser) do
          double(
            "Parser",
            model_class: Decidim::ParticipatoryProcess,
            model_title: { "en" => "Test Process", "ca" => "Procés de prova" },
            subtitle: { "en" => "Test Subtitle", "ca" => "Subtítol de prova" },
            short_description: { "en" => "Short description", "ca" => "Descripció curta" },
            description: { "en" => "A description", "ca" => "Una descripció" }
          )
        end

        subject(:importer) { described_class.new(parser, organization, user) }

        describe "#locales" do
          it "returns the organization's available locales" do
            expect(importer.locales).to eq(%w(en ca))
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
            expect(participatory_process.title).to eq({ "en" => "Test Process", "ca" => "Procés de prova" })
            expect(participatory_process.subtitle).to eq({ "en" => "Test Subtitle", "ca" => "Subtítol de prova" })
            expect(participatory_process.short_description).to eq({ "en" => "Short description", "ca" => "Descripció curta" })
            expect(participatory_process.description).to eq({ "en" => "A description", "ca" => "Una descripció" })
            expect(participatory_process.slug).to eq("test-process")
            expect(participatory_process.organization).to eq(organization)
          end
        end
      end
    end
  end
end
