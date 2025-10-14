# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitSyncronizer do
      let(:git_mirror) { create(:git_mirror, :with_commit) }

      before do
        allow(GitCatalogNormalizer).to receive(:call).and_return({ ok: true })
        allow(ResetOrganization).to receive(:call).and_return({ ok: true })
        allow(GitMirror.instance).to receive(:pull).and_return(true)
        allow(GitMirror.instance).to receive(:push!).and_return(true)
        CommunityTemplates.configure do |config|
          config.git_settings[:url] = git_mirror.repo_url
          config.git_settings[:branch] = git_mirror.repo_branch
          config.git_settings[:username] = git_mirror.repo_username
          config.git_settings[:password] = git_mirror.repo_password
          config.git_settings[:author_name] = git_mirror.repo_author_name
          config.git_settings[:author_email] = git_mirror.repo_author_email
        end
      end

      describe "#perform" do
        context "when git URL is not configured" do
          before do
            CommunityTemplates.configure do |config|
              config.git_settings[:url] = nil
            end
          end

          it "does not call GitCatalogNormalizer" do
            described_class.call
            expect(GitCatalogNormalizer).not_to have_received(:call)
          end

          it "does not pull from remote" do
            described_class.call
            expect(GitMirror.instance).not_to have_received(:pull)
          end

          it "does not push to remote" do
            described_class.call
            expect(GitMirror.instance).not_to have_received(:push!)
          end
        end

        context "when there are untracked files" do
          let(:git_mirror) { create(:git_mirror, :with_commit) }

          before do
            git_instance = git_mirror.git
            allow(git_instance).to receive(:git).and_return(git_instance)
            allow(GitMirror).to receive(:instance).and_return(git_mirror)

            fetch_double = double("fetch")
            allow(fetch_double).to receive(:fetch)
            allow(git_instance).to receive(:remote).and_return(fetch_double)

            branches_double = double("branches")
            main_branch_double = double("branch", name: "origin/main")
            allow(branches_double).to receive(:remote).and_return([main_branch_double])
            allow(branches_double).to receive(:local).and_return([main_branch_double])
            allow(git_instance).to receive(:branches).and_return(branches_double)
            FileUtils.touch(git_mirror.catalog_path.join("test.txt"))
          end

          it "calls GitCatalogNormalizer" do
            described_class.call
            expect(GitCatalogNormalizer).to have_received(:call)
          end

          it "pulls from remote repository" do
            described_class.call
            expect(GitMirror.instance).to have_received(:pull)
          end

          it "pushes to remote repository" do
            described_class.call
            expect(GitMirror.instance).to have_received(:push!)
          end
        end

        context "when there are no untracked files" do
          it "calls GitCatalogNormalizer" do
            described_class.call
            expect(GitCatalogNormalizer).to have_received(:call)
          end

          it "pulls from remote repository" do
            described_class.call
            expect(GitMirror.instance).to have_received(:pull)
          end

          it "does not create commit" do
            described_class.call
            expect(git_mirror.git.log(1).execute.last.message).not_to include("Update community templates")
          end
        end
      end
    end
  end
end
