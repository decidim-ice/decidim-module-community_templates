# frozen_string_literal: true

require "spec_helper"

describe "Participatory processes template tab" do
  let(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:fixture_path) { Decidim::CommunityTemplates::Engine.root.join("spec", "fixtures", "catalog_test", "valid") }

  before do
    allow(Decidim::CommunityTemplates).to receive(:catalog_path).and_return(Pathname.new(Dir.mktmpdir))
    allow(Decidim::CommunityTemplates).to receive(:enabled?).and_return(true)
    allow(Decidim::CommunityTemplates::GitSyncronizer).to receive(:call).and_return({ ok: true })
    switch_to_host(organization.host)
    FileUtils.rm_rf(Decidim::CommunityTemplates.catalog_path)
    FileUtils.cp_r(fixture_path, Decidim::CommunityTemplates.catalog_path)
    Decidim::CommunityTemplates::Catalog.from_path(Decidim::CommunityTemplates.catalog_path)
    login_as user, scope: :user
    visit decidim_admin_community_templates.community_templates_path
  end

  it "<title> the page with Community Templates" do
    expect(page).to have_title(/Community Templates/)
  end

  it "there is a tab which renders the templates link" do
    within(".main-nav li.is-active") do
      expect(page).to have_selector(:link_or_button, "Templates")
    end
  end

  it "does not have manage dropdown" do
    within(".process-title-content") do
      expect(page).to have_no_css(".process-title-content-breadcrumb-container-right")
    end
  end

  it "displays breadcrumb" do
    within(".process-title-content") do
      expect(page).to have_css("span.process-title-content-breadcrumb", text: "Templates")
    end
  end

  it "displays the template card" do
    within(".template-card__intro", text: "Idea Board Template") do
      expect(page).to have_css("h2", text: "Idea Board Template")
    end
  end

  it "parses markdown content in template card" do
    within(".template-card__intro", text: "Idea Board Template") do
      expect(page).to have_css(".catalog_summary__content a", text: "Octree")
    end
  end

  it "displays only host for links" do
    within(".template-card__intro", text: "Idea Board Template") do
      expect(page).to have_css(".catalog_summary__metadatas-item a[href='https://octree.ch']", text: "octree.ch")
    end
  end

  context "when there are no templates" do
    before do
      allow(Decidim::CommunityTemplates::Catalog).to receive(:from_path).and_return(Decidim::CommunityTemplates::Catalog.new(templates: []))
      visit decidim_admin_community_templates.community_templates_path
    end

    it "displays an empty state" do
      within(".template-cards__empty") do
        expect(page).to have_css("p", text: /is empty/)
      end
    end
  end
end
