# frozen_string_literal: true

require "spec_helper"

describe "Admin templates" do
  let(:organization) { create(:organization) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user

    visit decidim_admin.root_path
  end

  it "shows the admin menu" do
    click_on "Community templates"

    within "h1" do
      expect(page).to have_content("Community Templates")
    end
  end
end
