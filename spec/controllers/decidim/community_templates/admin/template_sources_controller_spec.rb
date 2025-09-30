# frozen_string_literal: true

require "spec_helper"

module Decidim::CommunityTemplates
  module Admin
    describe TemplateSourcesController do
      routes { Decidim::CommunityTemplates::AdminEngine.routes }
      def reload_catalog
        Decidim::CommunityTemplates::Catalog.from_path(Decidim::CommunityTemplates.catalog_path)
      end

      let(:user) { create(:user, :confirmed, :admin, organization:) }
      let(:organization) { create(:organization) }

      before do
        request.env["decidim.current_organization"] = user.organization
        sign_in user, scope: :user
      end

      describe "POST #create" do
        let(:template_source) { build(:community_template_source, organization:) }
        let(:participatory_process) { create(:participatory_process, organization:) }
        let(:template_params) do
          {
            name: Faker::Lorem.sentence,
            author: Faker::Name.name,
            links: [Faker::Internet.url(scheme: "https")],
            description: Faker::Lorem.sentence,
            version: Faker::Lorem.sentence
          }
        end

        it "creates a new template source" do
          expect do
            post :create, params: { template_source: { source_id: participatory_process.to_global_id.to_s, template: template_params } }
          end.to change(Decidim::CommunityTemplates::TemplateSource, :count).by(1)
          expect(response).to have_http_status(:redirect)
          expect(Decidim::CommunityTemplates::TemplateSource.last.source_id).to eq(participatory_process.id)
          expect(Decidim::CommunityTemplates::TemplateSource.last.source_type).to eq("Decidim::ParticipatoryProcess")
        end

        it "write to catalog" do
          post :create, params: { template_source: { source_id: participatory_process.to_global_id.to_s, template: template_params } }
          expect(response).to have_http_status(:redirect)
          catalog = reload_catalog
          match = catalog.templates.find { |template| template.name == template_params[:name] }
          expect(match).to be_present
          expect(Decidim::CommunityTemplates.catalog_path.join(match.id)).to be_exist
        end

        it "define a new template id" do
          expect do
            post :create, params: { template_source: { source_id: participatory_process.to_global_id.to_s, template: template_params } }
          end.to change(Decidim::CommunityTemplates::TemplateSource, :count).by(1)
          expect(response).to have_http_status(:redirect)
          catalog = reload_catalog
          match = catalog.templates.find { |template| template.name == template_params[:name] }
          expect(Decidim::CommunityTemplates::TemplateSource.last.template_id).to eq(match.id)
        end

        it "define default locale from organization" do
          post :create, params: { template_source: { source_id: participatory_process.to_global_id.to_s, template: template_params } }
          expect(response).to have_http_status(:redirect)
          catalog = reload_catalog
          match = catalog.templates.find { |template| template.name == template_params[:name] }
          expect(match.default_locale).to eq(organization.default_locale)
        end

        context "when the template is not valid" do
          let(:template_params) do
            {
              name: Faker::Lorem.sentence,
              author: Faker::Name.name,
              links: [Faker::Internet.url(scheme: "https")],
              description: Faker::Lorem.sentence,
              version: nil
            }
          end

          it "does not create a new template source" do
            expect do
              post :create, params: { template_source: { source_id: participatory_process.to_global_id.to_s, template: template_params } }
            end.not_to change(Decidim::CommunityTemplates::TemplateSource, :count)
            expect(response).to have_http_status(:redirect)
          end

          it "render modal.js.erb if xhr?" do
            post :create, params: { template_source: { source_id: participatory_process.to_global_id.to_s, template: template_params } }, xhr: true
            expect(response).to have_http_status(:success)
            expect(response).to render_template(partial: "decidim/community_templates/admin/template_sources/_template_modal_form")
          end
        end
      end

      describe "PUT #update" do
        let(:template_source) { create(:community_template_source, organization:) }
        let(:id) { template_source.template_id }
        let(:template_params) do
          {
            name: Faker::Lorem.sentence,
            author: Faker::Name.name,
            links: [Faker::Internet.url(scheme: "https")],
            description: Faker::Lorem.sentence,
            version: Faker::Lorem.sentence
          }
        end

        it "writes the template to the catalog" do
          put :update, params: { id: id, template_source: {
            source_id: template_source.source.to_global_id.to_s,
            template: template_params
          } }
          expect(response).to have_http_status(:redirect)
          catalog = reload_catalog
          expect(catalog.templates.find { |template| template.id == id }.name).to eq(template_params[:name])
        end

        context "when the template is not valid" do
          let(:template_params) do
            {
              name: Faker::Lorem.sentence,
              author: Faker::Name.name,
              links: [Faker::Internet.url(scheme: "https")],
              description: Faker::Lorem.sentence,
              version: nil
            }
          end

          it "raises a 404 if the template is not found" do
            expect do
              put :update, params: { id: "not_found", template_source: {
                source_id: template_source.source.to_global_id.to_s,
                template: template_params
              } }
            end.to raise_error(ActionController::RoutingError, "Not Found")
          end

          it "does not update the template" do
            expect do
              put :update, params: { id: id, template_source: {
                source_id: template_source.source.to_global_id.to_s,
                template: template_params
              } }
            end.not_to change(template_source, :updated_at)
            expect(response).to have_http_status(:redirect)
          end

          it "render modal.js.erb if xhr?" do
            put :update, params: { id: id, template_source: {
              source_id: template_source.source.to_global_id.to_s,
              template: template_params
            } }, xhr: true
            expect(response).to have_http_status(:success)
            expect(response).to render_template(partial: "decidim/community_templates/admin/template_sources/_template_modal_form")
          end
        end
      end
    end
  end
end
