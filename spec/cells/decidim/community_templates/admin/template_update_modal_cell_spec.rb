# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe TemplateUpdateModalCell, type: :cell do
        controller Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessesController
        def reload_catalog
          fixture_file_path = Decidim::CommunityTemplates::Engine.root.join("spec", "fixtures", "catalog_test", "valid")
          catalog = Decidim::CommunityTemplates::Catalog.from_path(fixture_file_path)
          catalog.templates.each { |t| t.owned = true }
          catalog.write(Decidim::CommunityTemplates.catalog_path)
          Decidim::CommunityTemplates::Catalog.from_path(Decidim::CommunityTemplates.catalog_path)
        end

        before do
          reload_catalog
        end

        let(:catalog) { reload_catalog }

        let(:my_cell) { cell("decidim/community_templates/admin/template_update_modal", template_source) }
        let(:template) { catalog.templates.first }
        let(:template_source) { create(:community_template_source, template_id: template.id) }
        let(:participatory_process) { template_source.source }

        subject { my_cell.call }

        it "submit asynchronously" do
          expect(subject).to have_css("form[data-remote='true']")
        end

        it "use a modal-template-<space.id> as modal id" do
          expect(subject).to have_css("#modal-template-#{participatory_process.id}")
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
          expect(subject).to have_field("template_source[template][title]", with: template.title)
          expect(subject).to have_field("template_source[template][author]", with: template.author)
          expect(subject).to have_field("template_source[template][links]")
          expect(subject).to have_field("template_source[template][short_description]")
        end

        it "have a disabled select field for the source_id" do
          expect(subject).to have_select("template_source[source_id]", disabled: true)
        end

        context "when passing form as option" do
          let(:another_template) { catalog.templates.last }

          let(:form) do
            Decidim::CommunityTemplates::Admin::TemplateSourceForm.new(
              source_id: template_source.source_id,
              template: another_template
            )
          end

          let(:my_cell) { cell("decidim/community_templates/admin/template_update_modal", template_source, form: form) }

          it "uses the form passed as option" do
            expect(subject).to have_field("template_source[template][title]", with: another_template.title)
            expect(subject).to have_field("template_source[template][author]", with: another_template.author)
          end

          context "when the form is invalid" do
            before do
              reload_catalog
              another_template.links = ["invalid_link"]
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
