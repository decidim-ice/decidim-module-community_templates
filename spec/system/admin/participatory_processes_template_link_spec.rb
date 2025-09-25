# frozen_string_literal: true

require "spec_helper"

describe "Participatory processes template link" do
  let(:organization) { create(:organization) }
  let!(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let!(:user) { create(:user, :admin, :confirmed, organization:) }

  context "when the community templates are disabled" do
    before do
      allow(Decidim::CommunityTemplates).to receive(:enabled?).and_return(false)
      switch_to_host(organization.host)
      login_as user, scope: :user
      visit decidim_admin_participatory_processes.participatory_processes_path
    end

    it "does not show the a link icon" do
      within("tr", text: translated(participatory_process.title)) do
        expect(page).to have_no_css("a.action-icon--templatize")
      end
    end
  end

  context "when the community templates are enabled" do
    before do
      allow(Decidim::CommunityTemplates).to receive(:enabled?).and_return(true)
    end

    context "when the repository is writable" do
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

    context "when the repository is not writable" do
      before do
        git_mirror = Decidim::CommunityTemplates::GitMirror.instance
        allow(Decidim::CommunityTemplates::GitMirror).to receive(:instance).and_return(git_mirror)
        allow(git_mirror).to receive(:writable?).and_return(false)
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
  end
end
