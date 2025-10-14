# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe ImportFromLinkController do
        routes { Decidim::CommunityTemplates::AdminEngine.routes }

        let(:user) { create(:user, :confirmed, :admin, organization:) }
        let(:organization) { create(:organization) }
        let(:valid_uuid) { "00605f97-a5d6-4464-9c7e-5bc5d5840212" }
        let(:valid_link) { "https://example.com/#{valid_uuid}" }
        let(:invalid_link) { "http://example.com/invalid" }
        let(:fixture_path) { Decidim::CommunityTemplates::Engine.root.join("spec", "fixtures", "catalog_test", "valid", valid_uuid) }
        let(:valid_data) do
          File.read(fixture_path.join("data.json"))
        end
        let(:valid_locales) do
          File.read(fixture_path.join("locales", "en.yml"))
        end

        before do
          allow(Decidim::CommunityTemplates::GitSyncronizer).to receive(:call).and_return({ok: true})

          request.env["decidim.current_organization"] = user.organization
          sign_in user, scope: :user
          
          # Mock HTTP requests for data.json
          allow(Net::HTTP).to receive(:get_response).with(URI.parse("#{valid_link}/data.json")).and_return(
            double(code: "200", body: valid_data)
          )
          
          # Mock HTTP requests for all available locale files
          %w[en ca es pt-BR].each do |locale|
            allow(Net::HTTP).to receive(:get_response).with(URI.parse("#{valid_link}/locales/#{locale}.yml")).and_return(
              double(code: "200", body: valid_locales)
            )
          end
        end

        describe "POST #create" do
          context "when request is not XHR" do
            it "raises InvalidRequestError" do
              expect do
                post :create, params: { direct_link: { link: valid_link } }
              end.to raise_error(NameError, /uninitialized constant.*InvalidRequestError/)
            end
          end

          context "when request is XHR" do
            context "when commit parameter is 'install'" do
              let(:params) { { direct_link: { link: valid_link }, commit: "install" } }

              it "processes the import request" do
                post :create, params: params, xhr: true
                expect(response).to have_http_status(:ok)
                expect(assigns(:form)).to be_present
              end
            end

            context "when commit parameter is not 'install'" do
              let(:params) { { direct_link: { link: valid_link }, commit: "fetch" } }

              it "renders form partial" do
                post :create, params: params, xhr: true
                expect(response).to render_template(partial: "decidim/community_templates/admin/import_from_link/_direct_link_modal_form")
              end

              it "validates the form" do
                post :create, params: params, xhr: true
                expect(assigns(:form)).to be_present
              end
            end

            context "when commit parameter is missing" do
              let(:params) { { direct_link: { link: valid_link } } }

              it "renders form partial" do
                post :create, params: params, xhr: true
                expect(response).to render_template(partial: "decidim/community_templates/admin/import_from_link/_direct_link_modal_form")
              end
            end
          end
        end
      end
    end
  end
end