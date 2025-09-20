# frozen_string_literal: true

require "spec_helper"

describe "Participatory processes template link" do
  let(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

  before do
    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_participatory_processes.participatory_processes_path
  end

  it "shows the a link icon" do
    within("tr", text: translated(participatory_process.title)) do
      expect(page).to have_css("a.action-icon--templatize")
    end
  end
end
