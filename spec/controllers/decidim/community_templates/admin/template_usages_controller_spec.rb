# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe TemplateUsagesController do
        routes { Decidim::CommunityTemplates::AdminEngine.routes }

        let(:user) { create(:user, :confirmed, :admin, organization:) }
        let(:organization) { create(:organization) }
        let(:valid_template_id) { "00605f97-a5d6-4464-9c7e-5bc5d5840212" }
        let(:invalid_template_id) { "invalid_id" }
        let(:fixture_path) { Engine.root.join("spec/fixtures/catalog_test/valid") }

        before do
          allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return(fixture_path)
          request.env["decidim.current_organization"] = user.organization
          sign_in user, scope: :user
        end

        describe "POST #create" do
          context "when the import is successful" do
            let(:params) { { template_id: valid_template_id } }

            before do
              # Create a template source for the valid fixture
              create(:community_template_source, template_id: valid_template_id, organization:)
            end

            it "validates the template metadata" do
              mocked = Decidim::CommunityTemplates::TemplateMetadata.find(valid_template_id)
              allow(mocked).to receive(:validate!).and_call_original
              allow(Decidim::CommunityTemplates::TemplateMetadata).to receive(:find).and_return(mocked)
              post :create, params: params
              expect(Decidim::CommunityTemplates::TemplateMetadata).to have_received(:find).with(valid_template_id)
              expect(mocked).to have_received(:validate!)
            end

            it "sets success flash message" do
              post :create, params: params
              expect(flash[:notice]).to eq(I18n.t("decidim.community_templates.admin.template_usages.create.success"))
            end

            it "redirects to the imported object edit page" do
              post :create, params: params
              expect(response).to have_http_status(:redirect)
            end

            it "creates a new space" do
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

          context "when the import fails due to invalid template" do
            let(:params) { { template_id: "invalid_template_id" } }

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

          context "when template metadata parsing fails" do
            let(:non_existent_id) { SecureRandom.uuid }
            let(:params) { { template_id: non_existent_id } }

            it "handles template parsing errors gracefully" do
              post :create, params: params
              expect(flash[:alert]).to eq(I18n.t("decidim.community_templates.admin.template_usages.create.error"))
              expect(response).to redirect_to(%r{/admin})
            end
          end
        end

        describe "private methods" do
          describe "#template_id" do
            it "returns the template_id from params" do
              controller.params = ActionController::Parameters.new(template_id: valid_template_id)
              expect(controller.send(:template_id)).to eq(valid_template_id)
            end
          end
        end
      end
    end
  end
end
