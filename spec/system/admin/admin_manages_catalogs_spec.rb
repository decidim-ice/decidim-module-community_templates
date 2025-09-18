# frozen_string_literal: true

require "spec_helper"

describe "Admin catalogs" do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user

    visit decidim_admin.root_path
  end

  it "shows the list of catalogs" do
    click_on "Community templates"
    click_on "Manage catalogs"
    within "h1" do
      expect(page).to have_content("Community Templates")
    end

    expect(page).to have_content("Community Templates Built-in Demo Catalog")
  end

  it "allows to import a catalog" do
    click_on "Community templates"
    click_on "Manage catalogs"
    click_on "Import"

    expect(page).to have_content("The catalog has been imported successfully.")
  end
end
