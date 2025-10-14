# frozen_string_literal: true

require "spec_helper"

describe "Create template from participatory process", js: true do
  let(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

  before do
    allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return(Pathname.new(Dir.mktmpdir))
    allow(Decidim::CommunityTemplates).to receive(:enabled?).and_return(true)
    allow(Decidim::CommunityTemplates::GitSyncronizer).to receive(:call).and_return({ ok: true })
    git_mirror = Decidim::CommunityTemplates::GitMirror.instance
    allow(Decidim::CommunityTemplates::GitMirror).to receive(:instance).and_return(git_mirror)
    allow(git_mirror).to receive(:writable?).and_return(true)

    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_participatory_processes.participatory_processes_path
    find("a.action-icon--templatize:first-child").click
  end

  it "display a creation modal" do
    expect(page).to have_css(".template-modal--create")
    expect(page).to have_css(".template-modal__title", text: "Community template")
  end

  it "display errors if form is not valid" do
    fill_in "Template title", with: "This is a valid title"
    fill_in "Author", with: "Capybara"
    fill_in "Links", with: "https://firstvalid.com, second_invalid_link"
    fill_in "Version", with: "V0.0.1"
    fill_in "Short description", with: "Just an invalid form"
    click_on "Create & Share"
    within(".template-modal--create") do
      expect(page).to have_css("label[for='template_source_template_links'] .form-error", text: "must be valid links starting with https://")
    end
  end

  context "when the form is valid" do
    before do
      fill_in "Template title", with: "This is a valid title"
      fill_in "Author", with: "Capybara"
      fill_in "Links", with: "https://firstvalid.com, https://secondvalid.com"
      fill_in "Version", with: "V0.0.1"
      fill_in "Short description", with: "Just an a valid form"
      click_on "Create & Share"
    end

    it "display a success message" do
      expect(page).to have_css(".template_success_modal__title")
    end

    context "when catalog is writable" do
      before do
        git_mirror = Decidim::CommunityTemplates::GitMirror.instance
        allow(git_mirror).to receive(:writable?).and_return(true)
      end

      it "display a link to show template in catalog" do
        expect(page).to have_css(".template_success_modal__catalog_link", text: "View it here")
      end

      it "have written the template in the catalog" do
        click_on "View it here"
        template_id = page.current_url.split("#").last
        expect(page).to have_css("##{template_id} .catalog_summary__title", text: "This is a valid title")
      end

      it "displays a sharable link to the template" do
        expect(page).to have_css("#template-js-public-url", text: %r{https://#{organization.host}/catalog/})
      end
    end

    context "when catalog is not writable" do
      before do
        git_mirror = Decidim::CommunityTemplates::GitMirror.instance
        allow(git_mirror).to receive(:writable?).and_return(false)
      end

      it "does not display a link to show template in catalog" do
        expect(page).to have_no_css(".template_success_modal__catalog_link", text: "View it here")
      end

      it "displays a sharable link to the template" do
        expect(page).to have_css("#template-js-public-url", text: %r{https://#{organization.host}/catalog/})
      end
    end
  end
end
