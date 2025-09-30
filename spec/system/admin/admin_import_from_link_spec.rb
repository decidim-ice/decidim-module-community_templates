# frozen_string_literal: true

require "spec_helper"

describe "Admin import template from link" do
  let(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

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
        within("#template-direct-link-modal-content") do
          expect(page).to have_content("There is an error in this field.")
        end
      end

      it "displays error if manifest.json file is not found" do
        allow(Net::HTTP).to receive(:get_response).and_return(double(code: "404", body: ""))
        fill_in "Link", with: "https://example.com"
        click_on "Go"
        within("#template-direct-link-modal-content") do
          expect(page).to have_content("Does not looks like a valid template link")
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
        let(:manifest_file) { File.read(Decidim::CommunityTemplates::Engine.root.join("spec/fixtures/catalog_test/valid/00605f97-a5d6-4464-9c7e-5bc5d5840212/data.json")) }

        before do
          allow(Net::HTTP).to receive(:get_response).and_return(double(code: "200", body: manifest_file))
          fill_in "Link", with: "https://example.com/catalog/0565b415-13a9-4d4a-baaa-da74c8847e20"
          click_on "Go"
        end

        it "enable the install and try demo buttons" do
          within("#template-direct-link-modal-content") do
            expect(page).to have_css("a.template-direct-link__link")
            expect(page).to have_no_css(".template-direct-link__link--disabled")
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
