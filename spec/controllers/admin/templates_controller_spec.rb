# frozen_string_literal: true

require "spec_helper"

module Decidim::CommunityTemplates
  module Admin
    describe TemplatesController do
      routes { Decidim::CommunityTemplates::AdminEngine.routes }

      let(:user) { create(:user, :confirmed, :admin, organization:) }
      let(:organization) { create(:organization) }

      before do
        request.env["decidim.current_organization"] = user.organization
        sign_in user, scope: :user
      end

      describe "GET #index" do
        it "returns http success" do
          get :index, params: {}
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
