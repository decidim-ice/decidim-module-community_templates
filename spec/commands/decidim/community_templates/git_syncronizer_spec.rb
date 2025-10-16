# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitSyncronizer do
      let(:git_mirror) { create(:git_mirror, :with_commit) }
      let(:git_instance) { git_mirror.open_git }

      before do
        # Mock GitCatalogNormalizer and ResetOrganization
        allow(GitCatalogNormalizer).to receive(:call).and_return({ ok: true })
        allow(ResetOrganization).to receive(:call).and_return({ ok: true })

        # Mock GitMirror.instance methods
        allow(GitMirror).to receive(:instance).and_return(git_mirror)
        allow(git_mirror).to receive(:pull!).and_return(true)
        allow(git_mirror).to receive(:last_commit).and_return("abc123")
        allow(git_mirror).to receive(:transaction).and_yield(git_instance)

        # Mock git instance methods to prevent network calls
        allow(git_instance).to receive(:pull).and_return(true)
        allow(git_instance).to receive(:add).and_return(true)
        allow(git_instance).to receive(:commit).and_return(true)
        allow(git_instance).to receive(:status).and_return(double("status", changed: [], added: [], deleted: [], untracked: []))
        allow(git_instance).to receive(:log).and_return(double("log", execute: [double("commit", message: "test commit")]))

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
            expect(git_mirror).not_to have_received(:pull!)
          end

          it "does not call last_commit" do
            described_class.call
            expect(git_mirror).not_to have_received(:last_commit)
          end
        end

        context "when there are untracked files" do
          before do
            # Mock the pull! method to raise GitError directly
            allow(git_mirror).to receive(:pull!).and_raise(GitError, "catalog dirty, commit or stash changes to continue")
          end

          it "raise a GitError, dirty catalog" do
            expect { described_class.call }.to raise_error(GitError)
          end
        end

        context "when there are no untracked files" do
          before do
            # Mock GitTransaction to work normally for this context
            allow(GitTransaction).to receive(:perform).and_yield(git_instance)
            # Ensure clean status
            allow(git_instance).to receive(:status).and_return(
              double("status",
                     changed: [],
                     added: [],
                     deleted: [],
                     untracked: [])
            )
          end

          it "calls GitCatalogNormalizer" do
            described_class.call
            expect(GitCatalogNormalizer).to have_received(:call)
          end

          it "pulls from remote repository" do
            described_class.call
            expect(git_mirror).to have_received(:pull!)
          end

          it "calls last_commit" do
            described_class.call
            expect(git_mirror).to have_received(:last_commit)
          end

          it "does not create commit" do
            described_class.call
            expect(git_instance).not_to have_received(:add)
            expect(git_instance).not_to have_received(:commit)
          end
        end
      end
    end
  end
end
