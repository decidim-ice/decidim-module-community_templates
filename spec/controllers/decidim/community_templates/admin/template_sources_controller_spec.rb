# frozen_string_literal: true

require "spec_helper"

module Decidim::CommunityTemplates
  module Admin
    describe TemplateSourcesController do
      routes { Decidim::CommunityTemplates::AdminEngine.routes }

      let(:user) { create(:user, :confirmed, :admin, organization:) }
      let(:organization) { create(:organization) }

      before do
        request.env["decidim.current_organization"] = user.organization
        sign_in user, scope: :user
      end

      describe "PUT #update" do
        let(:template_source) { create(:community_template_source, organization:) }
        let(:id) { template_source.template_id }
        let(:template_params) do
          {
            title: "Another Template",
            author: "Another Author",
            links: ["https://example.com"],
            short_description: "Another Short Description",
            version: "Another Version"
          }
        end

        it "writes the template to the catalog" do
          put :update, params: { id: id, template_source: {
            source_id: template_source.source.to_global_id.to_s,
            template: template_params
          } }
          expect(response).to have_http_status(:redirect)
          catalog = Decidim::CommunityTemplates::Catalog.from_path(Decidim::CommunityTemplates.catalog_path)
          expect(catalog.templates.find { |template| template.id == id }.title).to eq("Another Template")
        end

        it "raises a 404 if the template is not found" do
          expect do
            put :update, params: { id: "not_found", template_source: {
              source_id: template_source.source.to_global_id.to_s,
              template: template_params
            } }
          end.to raise_error(ActionController::RoutingError, "Not Found")
        end
      end
    end
  end
end
