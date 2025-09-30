# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe ImportTemplateForm, type: :form do
        let(:organization) { create(:organization, default_locale: :en, available_locales: [:en, :es]) }
        let(:context) { { current_organization: organization } }
        let(:id) { "folder_123" }
        let(:form) { described_class.new(id: id, demo: true).with_context(**context) }

        describe "#template_path" do
          it "returns the correct template path" do
            allow(Decidim::CommunityTemplates).to receive(:local_path).and_return("/tmp/templates")
            expect(form.template_path).to eq("/tmp/templates/folder_123")
          end
        end

        describe "#locales" do
          it "returns the default and available locales as strings, uniq" do
            expect(form.locales).to match_array(%w(en es))
          end
        end

        describe "#parser" do
          it "returns a TemplateParser instance with correct path and locales" do
            allow(form).to receive(:template_path).and_return("spec/fixtures/template_test")
            parser = form.parser
            expect(parser).to be_a(Decidim::CommunityTemplates::TemplateParser)
          end
        end
      end
    end
  end
end
