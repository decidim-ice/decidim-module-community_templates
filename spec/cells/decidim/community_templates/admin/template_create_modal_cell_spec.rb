# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe TemplateCreateModalCell, type: :cell do
        controller Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessesController

        let(:participatory_process) { create(:participatory_process) }
        let(:my_cell) { cell("decidim/community_templates/admin/template_create_modal", participatory_process) }

        subject { my_cell.call }

        it "submit asynchronously" do
          expect(subject).to have_css("form[data-remote='true']")
        end

        it "use a modal-template-<participatory_process.id> as modal id" do
          expect(subject).to have_css("#modal-template-#{participatory_process.id}")
        end

        it "have a POST form" do
          expect(subject).to have_css("form[method='post']")
          expect(subject).to have_css("form[action='/admin/community_templates/template_sources']")
        end

        it "have a modal" do
          expect(subject).to have_css("[data-dialog-container]")
          expect(subject).to have_css("[data-dialog-title]")
          expect(subject).to have_css("[data-dialog-actions]")
        end

        it "is closable" do
          expect(subject).to have_css("[data-dialog-close='modal-template-#{participatory_process.id}']")
        end

        it "have fields for the template form" do
          expect(subject).to have_field("template_source[template][title]")
          expect(subject).to have_field("template_source[template][author]")
          expect(subject).to have_field("template_source[template][links]")
          expect(subject).to have_field("template_source[template][short_description]")
        end

        it "have a disabled select field for the source_id" do
          expect(subject).to have_select("template_source[source_id]", disabled: true)
        end

        context "when passing form as option" do
          let(:another_template) do
            Decidim::CommunityTemplates::Template.new(
              title: "Another Template",
              author: "Another Author",
              links: ["https://example.com"],
              short_description: "Another Short Description"
            )
          end
          let(:form) do
            Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
              source_id: participatory_process.id,
              template: another_template
            )
          end

          let(:my_cell) { cell("decidim/community_templates/admin/template_create_modal", participatory_process, form: form) }

          it "uses the form passed as option" do
            expect(subject).to have_field("template_source[template][title]", with: another_template.title)
            expect(subject).to have_field("template_source[template][author]", with: another_template.author)
          end

          context "when the form is invalid" do
            before do
              another_template.links = ["invalid_link"]
              form.validate
            end

            it "shows the errors" do
              expect(subject).to have_css(".form-error")
              expect(subject).to have_css(".form-error", text: "must be valid links starting with https://")
            end
          end
        end
      end
    end
  end
end
