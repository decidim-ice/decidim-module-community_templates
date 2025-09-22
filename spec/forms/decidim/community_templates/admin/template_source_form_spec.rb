# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe TemplateSourceForm do
        let(:template) { create(:template) }
        let(:participatory_process) { create(:participatory_process) }
        let(:form) { described_class.new(template: template, source_id: participatory_process.to_global_id.to_s) }

        it "is valid with valid attributes" do
          expect(form).to be_valid
        end

        it "is invalid with wrong source_id" do
          form.source_id = "wrong"
          expect(form).to be_invalid
        end

        it "is invalid with nil template" do
          form.template = nil
          expect(form).to be_invalid
        end

        it "is invalid with nil source_id" do
          form.source_id = nil
          expect(form).to be_invalid
        end

        it "validates the template" do
          allow(template).to receive(:valid?).and_return(true)
          form.valid?
          expect(template).to have_received(:valid?)
        end
      end
    end
  end
end
