# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe TemplateUsagesController do
        routes { Decidim::CommunityTemplates::AdminEngine.routes }

        let(:user) { create(:user, :confirmed, :admin, organization:) }
        let(:organization) { create(:organization) }
        let(:template_metadata) { create(:template_metadata, organization:) }
        let(:template_id) { template_metadata.id }

        before do
          request.env["decidim.current_organization"] = user.organization
          sign_in user, scope: :user
        end

        describe "POST #create" do
          let(:params) { { template_id: template_id } }

          context "when the import is successful" do
            before do
              # Mock the form to be valid and return a proper importer
              allow_any_instance_of(Decidim::CommunityTemplates::Admin::ImportTemplateForm).to receive(:valid?).and_return(true)
              allow_any_instance_of(Decidim::CommunityTemplates::Admin::ImportTemplateForm).to receive(:importer).and_return(
                double("Importer", new: double("ImporterInstance", import!: true, object: create(:participatory_process, organization:)))
              )
              allow(Decidim::CommunityTemplates::TemplateMetadata).to receive(:find).and_call_original
            end

            it "finds the template metadata" do
              post :create, params: params
              expect(Decidim::CommunityTemplates::TemplateMetadata).to have_received(:find).with(template_id)
            end

            it "sets success flash message" do
              post :create, params: params
              expect(flash[:notice]).to eq(I18n.t("decidim.community_templates.admin.template_usages.create.success"))
            end

            it "redirects to the imported object edit page" do
              post :create, params: params
              expect(response).to have_http_status(:redirect)
            end

            it "create a new space" do
              expect do
                post :create, params: params
              end.to change(Decidim::ParticipatoryProcess, :count).by(1)
            end

            it "creates a new template use" do
              expect do
                post :create, params: params
              end.to change(Decidim::CommunityTemplates::TemplateUse, :count).by(1)
              expect(Decidim::ParticipatoryProcess.find(Decidim::CommunityTemplates::TemplateUse.last.resource_id)).to be_present
            end
          end

          context "when the import fails" do
            before do
              # Mock the form to be invalid
              allow_any_instance_of(Decidim::CommunityTemplates::Admin::ImportTemplateForm).to receive(:valid?).and_return(false)
              allow_any_instance_of(Decidim::CommunityTemplates::Admin::ImportTemplateForm).to receive(:errors).and_return(
                double("Errors", full_messages: ["Template is invalid"])
              )
            end

            it "sets error flash message" do
              post :create, params: params
              expect(flash[:alert]).to eq(I18n.t("decidim.community_templates.admin.template_usages.create.error"))
            end

            it "redirects back to admin root" do
              post :create, params: params
              expect(response).to redirect_to(%r{/admin})
            end
          end

          context "when template_id parameter is missing" do
            it "raises ActionController::ParameterMissing" do
              expect do
                post :create, params: {}
              end.to raise_error(ActionController::ParameterMissing, /template_id/)
            end
          end

          context "when template metadata is not found" do
            before do
              allow(Decidim::CommunityTemplates::TemplateMetadata).to receive(:find).with(template_id).and_raise(ActiveRecord::RecordNotFound)
            end

            it "raises ActiveRecord::RecordNotFound" do
              expect do
                post :create, params: params
              end.to raise_error(ActiveRecord::RecordNotFound)
            end
          end
        end

        describe "private methods" do
          describe "#template_id" do
            it "returns the template_id from params" do
              controller.params = ActionController::Parameters.new(template_id: template_id)
              expect(controller.send(:template_id)).to eq(template_id)
            end
          end
        end
      end
    end
  end
end
