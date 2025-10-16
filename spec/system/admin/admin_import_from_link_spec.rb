# frozen_string_literal: true

require "spec_helper"

describe "Admin import template from link" do
  let(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }
  let!(:git_mirror) { Decidim::CommunityTemplates::GitMirror.instance }
  let(:git_settings) { create(:git_settings) }
  let(:git_dir) { Rails.root.join("tmp", "catalog-#{SecureRandom.hex(4)}") }
  let(:git_instance) { create(:git, settings: git_settings, path: git_dir) }

  before do
    allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return(git_dir)
    allow(Decidim::CommunityTemplates).to receive(:enabled?).and_return(true)

    Decidim::CommunityTemplates::GitMirror.instance.configure(
      git_settings.attributes
    )

    allow(git_instance).to receive(:push).and_return(true)
    allow(git_instance).to receive(:pull).and_return(true)
    allow(Git).to receive(:clone).and_return(git_instance)
    allow(Git).to receive(:open).and_return(git_instance)

    allow(Decidim::CommunityTemplates::GitTransaction).to receive(:perform).and_yield(git_instance)
  end

  context "when the community templates are disabled" do
    before do
      allow(Decidim::CommunityTemplates).to receive(:enabled?).and_return(false)
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_admin_participatory_processes.participatory_processes_path
      click_on "Manage"
    end

    it "does not show the a import from direct link button" do
      within("#processes-dropdown-menu-settings") do
        expect(page).to have_no_css(".module-template-direct_link")
      end
    end
  end

  context "when the community templates are enabled" do
    before do
      allow(Decidim::CommunityTemplates).to receive(:enabled?).and_return(true)
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_admin_participatory_processes.participatory_processes_path
      click_on "Manage"
    end

    it "shows the a import from direct link button" do
      within("#processes-dropdown-menu-settings") do
        expect(page).to have_css(".module-template-direct_link")
      end
    end

    context "when clicking on import link" do
      before do
        click_on "Create from link"
      end

      it "add anchor #js-import-from-link to the url" do
        expect(page.current_url).to include("#js-import-from-link")
      end

      it "shows create from link modal" do
        expect(page).to have_css("#template-direct-link-modal-content")
      end

      it "displays error if form is not valid" do
        click_on "Go"
        within("#template-direct-link-modal-content", wait: 10) do
          expect(page).to have_content("There is an error in this field.")
        end
      end

      it "displays error if data.json file is not found" do
        allow(Net::HTTP).to receive(:get_response).and_return(double(code: "404", body: ""))
        fill_in "Link", with: "https://example.com"
        click_on "Go"
        within("#template-direct-link-modal-content .form-error.is-visible.template-direct-link__input") do
          expect(page).to have_content(/Manifest file not found/)
        end
      end

      it "disable the install and try demo buttons" do
        within("#template-direct-link-modal-content") do
          expect(page).to have_css("span.template-direct-link__link--disabled")
        end
      end

      context "when closing dialog (close button)" do
        before do
          find("button[data-dialog-close='template-direct-link-modal'][aria-label='Close modal']").click
        end

        it "remove the anchor #js-import-from-link from the url" do
          expect(page.current_url).not_to include("#js-import-from-link")
        end

        it "close the dialog" do
          expect(page).to have_no_css("#template-direct-link-modal-content")
        end

        it "reload the page" do
          expect(page).to have_current_path(decidim_admin_participatory_processes.participatory_processes_path)
        end
      end

      context "when the form is valid and submitted" do
        let(:data_file) { File.read(Decidim::CommunityTemplates::Engine.root.join("spec/fixtures/catalog_test/valid/00605f97-a5d6-4464-9c7e-5bc5d5840212/data.json")) }
        let(:assets_file) { File.read(Decidim::CommunityTemplates::Engine.root.join("spec/fixtures/catalog_test/valid/00605f97-a5d6-4464-9c7e-5bc5d5840212/assets.json")) }
        let(:city_image) { File.read(Decidim::CommunityTemplates::Engine.root.join("spec/fixtures/catalog_test/valid/00605f97-a5d6-4464-9c7e-5bc5d5840212/assets/m0nidedltelows9rmtzsz0k5vhziut09")) }
        let(:locale_file) { File.read(Decidim::CommunityTemplates::Engine.root.join("spec/fixtures/catalog_test/valid/00605f97-a5d6-4464-9c7e-5bc5d5840212/locales/en.yml")) }
        let(:catalog_url) { "https://example.com/catalog/00605f97-a5d6-4464-9c7e-5bc5d5840212" }

        before do
          allow(Decidim::CommunityTemplates::HttpTemplateExtractor).to receive(:fetch).with(
            "#{catalog_url}/data.json"
          ).and_return(data_file)
          allow(Decidim::CommunityTemplates::HttpTemplateExtractor).to receive(:fetch).with(
            "#{catalog_url}/assets.json"
          ).and_return(assets_file)
          allow(Decidim::CommunityTemplates::HttpTemplateExtractor).to receive(:fetch).with(
            "#{catalog_url}/assets/m0nidedltelows9rmtzsz0k5vhziut09"
          ).and_return(city_image)
          I18n.available_locales.each do |locale|
            allow(Decidim::CommunityTemplates::HttpTemplateExtractor).to receive(:fetch).with(
              "#{catalog_url}/locales/#{locale}.yml"
            ).and_return(locale_file)
          end
          fill_in "Template Link", with: catalog_url
          click_on "Go"
        end

        it "enable the install and try demo buttons" do
          within("#template-direct-link-modal-content") do
            expect(page).to have_button("Install")
            expect(page).to have_no_css(".template-direct-link__link--disabled")
          end
          within(".template-direct-link__form-section") do
            expect(page).to have_css(".catalog_summary__title", text: "Idea Board Template")
            expect(page).to have_css(".catalog_summary__metadatas-item", text: /v0\.1/)
            expect(page).to have_css(".catalog_summary__content", text: /ask participants for ideas/)
          end
        end

        context "when closing dialog (close button)" do
          before do
            find("button[data-dialog-close='template-direct-link-modal'][aria-label='Close modal']").click
          end

          it "remove the anchor #js-import-from-link from the url" do
            expect(page.current_url).not_to include("#js-import-from-link")
          end

          it "close the dialog" do
            expect(page).to have_no_css("#template-direct-link-modal-content")
          end

          it "reload the page" do
            expect(page).to have_current_path(decidim_admin_participatory_processes.participatory_processes_path)
          end
        end
      end
    end
  end
end
