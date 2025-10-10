# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe ImportTemplateForm, type: :form do
        let(:organization) { create(:organization, default_locale: :en, available_locales: [:en, :"pt-BR"]) }
        let(:context) { { current_organization: organization } }
        let(:id) { "folder_123" }
        let(:form) { described_class.new(id: id).with_context(**context) }

        describe "#template_path" do
          it "returns the correct template path" do
            allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return("/tmp/templates")
            expect(form.template_path).to eq("/tmp/templates/folder_123")
          end
        end

        describe "#locales" do
          it "returns the default and available locales as strings" do
            expect(form.locales).to match_array(%w(en pt-BR))
          end

          it "removes duplicates" do
            allow(organization).to receive(:available_locales).and_return(%w(en pt-BR en))
            expect(form.locales).to eq(%w(en pt-BR))
          end
        end

        describe "#importer_class" do
          it "returns the correct importer class" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test/valid")
            expect(form.importer_class).to eq("Decidim::CommunityTemplates::Importers::ParticipatoryProcess")
          end
        end

        describe "#importer" do
          it "returns the correct importer" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test/valid")
            expect(form.importer.name).to eq("Decidim::CommunityTemplates::Importers::ParticipatoryProcess")
          end

          it "returns nil if the importer is not found" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test/invalid_id")
            expect(form.importer).to be_nil
          end
        end

        describe "#importer?" do
          it "returns true if the importer is found" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test/valid")
            expect(form).to be_importer
          end

          it "returns false if the importer is not found" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test/invalid_id")
            expect(form).not_to be_importer
          end

          it "returns false if the template metadata is not found" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test/404")
            expect(form).not_to be_importer
          end
        end

        describe "#parser" do
          it "returns a TemplateParser instance with correct path and locales" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test/valid")
            parser = form.parser
            expect(parser).to be_a(Decidim::CommunityTemplates::TemplateParser)
            expect(parser.data).to include("id")
          end

          it "return nil if the parser is invalid" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test/404")
            expect(form.parser).to be_nil
          end
        end
      end
    end
  end
end
