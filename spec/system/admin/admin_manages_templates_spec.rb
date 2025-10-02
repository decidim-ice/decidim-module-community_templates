# frozen_string_literal: true

require "spec_helper"

describe "Admin templates" do
  let(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

  before do
    organization.update(available_locales: ["en", "ca", "pt-BR"])
    switch_to_host(organization.host)
    login_as user, scope: :user

    visit decidim_admin.root_path
    click_on "Community templates"
  end

  it "shows the admin menu" do
    within "h1" do
      expect(page).to have_content("Community Templates")
    end
  end

  context "when managing templates" do
    before do
      # clear the local templates folder
      FileUtils.rm_rf(Decidim::CommunityTemplates.local_path)
    end

    it "lists external templates" do
      click_on "External templates"

      expect(page).to have_content("There are no templates. Please download some from a catalog.")
    end

    context "when there are external templates" do
      before do
        path = "#{Decidim::CommunityTemplates.local_path}/external/pp-template-001"
        FileUtils.mkdir_p(path)
        FileUtils.cp_r("spec/fixtures/template_test", path)
      end

      it "lists external templates" do
        click_on "External templates"

        expect(page).to have_content("Participatory process template")
        expect(page).to have_content("A template for participatory processes")
        expect(page).to have_content("1.0.0")
        expect(page).to have_content("Apply in a new participatory space")
      end

      it "imports an external template" do
        click_on "External templates"
        click_on "Apply in a new participatory space"

        check "Include demo data"
        click_on "Create the new participatory space"

        expect(page).to have_content("The participatory space has been created successfully.")
        expect(Decidim::ParticipatoryProcess.last.title).to eq({ "en" => "Participatory process title", "ca" => "Títol del procés participatiu", "pt-BR" => "Título do processo participativo" })
      end
    end

    it "lists local templates" do
      click_on "Local templates"

      expect(page).to have_content("here are no local templates. All newly created templates will appear here.")
    end

    it "creates a new template" do
      click_on "Create template"
      select translated_attribute(participatory_process.title), from: "Select the participatory space you want to use as a template"
      click_on "Create the new template"

      fill_in_i18n(:template_name, "#template-name-tabs", { "ca" => "Nom del template", "en" => "Template name" })
      fill_in_i18n(:template_description, "#template-description-tabs", { "ca" => "Descripció del template", "en" => "Template description" })
      fill_in "Version", with: "1.0.0"
      click_on "Create the new template"

      expect(page).to have_content("The template has been created successfully.")
      expect(page).to have_content("Apply in a new participatory space")
    end
  end
end
