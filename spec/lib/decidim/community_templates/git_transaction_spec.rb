# frozen_string_literal: true

require "spec_helper"
require "decidim/community_templates/git_transaction"

module Decidim
  module CommunityTemplates
    describe GitTransaction do
      let(:git) { create(:git) }
      let(:git_transaction) { described_class.new(git) }
      let(:default_branch) { "main" }

      before do
        allow(git_transaction).to receive(:ensure_git_is_present!)
        allow(Decidim::CommunityTemplates).to receive(:git_settings).and_return({ branch: "main" })
      end

      describe "#initialize" do
        it "sets the git instance and timeout" do
          expect(git_transaction.instance_variable_get(:@git)).to eq(git)
          expect(git_transaction.instance_variable_get(:@timeout)).to eq(60)
        end

        it "configures git timeout" do
          expect(Git.config.timeout).to eq(60)
        end
      end

      describe "#perform" do
        let(:remote) { "origin" }
        let(:push_opts) { {} }
        let(:timeout) { nil }

        context "when repository is clean" do
          before do
            allow(git_transaction).to receive(:dirty?).and_return(false)
            allow(git_transaction).to receive(:writable?).and_return(true)
            allow(git_transaction).to receive(:default_branch).and_return(default_branch)
            allow(git_transaction).to receive(:assert_head_on!)
            allow(git_transaction).to receive(:merge_with_retries)
            allow(git_transaction).to receive(:push_with_retries)
          end

          it "executes the block on a transaction branch" do
            expect(git.current_branch).to eq(default_branch)
            git_transaction.perform(remote: remote, push_opts: push_opts, timeout: timeout) do |g|
              expect(g).to eq(git)
              expect(g.current_branch).to match(%r{^tx/\d{14}-[a-f0-9]{8}$})
            end
            expect(git.current_branch).to eq(default_branch)
          end

          it "merges and pushes when writable" do
            expect(git_transaction).to receive(:merge_with_retries).with(%r{^tx/\d{14}-[a-f0-9]{8}$})
            expect(git_transaction).to receive(:push_with_retries).with(remote, push_opts)

            git_transaction.perform(remote: remote, push_opts: push_opts) do
              # do nothing
            end
          end

          it "stashes changes when not writable" do
            allow(git_transaction).to receive(:writable?).and_return(false)
            expect(git_transaction).to receive(:safe_checkout).with(%r{^tx/\d{14}-[a-f0-9]{8}$}).at_least(:once)
            expect(git_transaction).to receive(:safe_checkout).with(default_branch).at_least(:once)
            expect(git_transaction).to receive(:safe_delete_branch).with(%r{^tx/\d{14}-[a-f0-9]{8}$})

            git_transaction.perform(remote: remote, push_opts: push_opts) do
              # do nothing
            end
          end

          it "uses custom timeout when provided" do
            custom_timeout = 120
            expect(git_transaction).to receive(:with_timeout).with(custom_timeout)

            git_transaction.perform(remote: remote, push_opts: push_opts, timeout: custom_timeout) do
              # do nothing
            end
          end

          it "uses default timeout when none provided" do
            expect(git_transaction).to receive(:with_timeout).with(60)

            git_transaction.perform(remote: remote, push_opts: push_opts) do
              # do nothing
            end
          end
        end

        context "when repository is dirty" do
          before do
            allow(git_transaction).to receive(:dirty?).and_return(true)
          end

          it "raises Git::Error" do
            expect do
              git_transaction.perform(remote: remote, push_opts: push_opts) do
                # do nothing
              end
            end.to raise_error(Git::Error, "catalog dirty, commit or stash changes to continue")
          end
        end

        context "when block raises Git::Error" do
          before do
            allow(git_transaction).to receive(:dirty?).and_return(false)
            allow(git_transaction).to receive(:writable?).and_return(true)
            allow(git_transaction).to receive(:default_branch).and_return(default_branch)
            allow(git_transaction).to receive(:assert_head_on!)
            allow(git_transaction).to receive(:safe_checkout)
            allow(git_transaction).to receive(:safe_delete_branch)
          end

          it "rolls back to default branch and re-raises error" do
            error = Git::Error.new("test error")
            expect(git_transaction).to receive(:safe_checkout).with(default_branch)
            expect(git_transaction).to receive(:safe_delete_branch).with(%r{^tx/\d{14}-[a-f0-9]{8}$})

            expect do
              git_transaction.perform(remote: remote, push_opts: push_opts) do
                raise error
              end
            end.to raise_error(Git::Error, "test error")
          end
        end

        context "when merge fails" do
          before do
            allow(git_transaction).to receive(:dirty?).and_return(false)
            allow(git_transaction).to receive(:writable?).and_return(true)
            allow(git_transaction).to receive(:default_branch).and_return(default_branch)
            allow(git_transaction).to receive(:assert_head_on!)
            allow(git_transaction).to receive(:merge_with_retries).and_raise(Git::Error.new("merge failed"))
            allow(git_transaction).to receive(:safe_checkout)
            allow(git_transaction).to receive(:safe_delete_branch)
          end

          it "rolls back and re-raises error" do
            expect(git_transaction).to receive(:safe_checkout).with(default_branch)
            expect(git_transaction).to receive(:safe_delete_branch).with(%r{^tx/\d{14}-[a-f0-9]{8}$})

            expect do
              git_transaction.perform(remote: remote, push_opts: push_opts) do
                # do nothing
              end
            end.to raise_error(Git::Error, "merge failed")
          end
        end

        context "when still dirty after merge" do
          before do
            allow(git_transaction).to receive(:dirty?).and_return(false, true) # clean initially, dirty after merge
            allow(git_transaction).to receive(:writable?).and_return(true)
            allow(git_transaction).to receive(:default_branch).and_return(default_branch)
            allow(git_transaction).to receive(:assert_head_on!)
            allow(git_transaction).to receive(:merge_with_retries)
            allow(git_transaction).to receive(:push_with_retries)
          end

          it "raises error about merge failure" do
            expect do
              git_transaction.perform(remote: remote, push_opts: push_opts) do
                # do nothing
              end
            end.to raise_error(RuntimeError, "merge fails, still dirty")
          end
        end
      end

      describe "#writable?" do
        let(:repo_url) { "https://user:pass@example.com/repo.git" }
        let(:remote) { double("remote", url: repo_url) }
        let(:index) { double("index", writable?: true) }

        before do
          allow(git).to receive(:remote).with("origin").and_return(remote)
          allow(git).to receive(:index).and_return(index)
        end

        it "returns true when repository has credentials and is writable" do
          expect(git_transaction.send(:writable?)).to be true
        end

        it "returns false when repository URL is blank" do
          allow(remote).to receive(:url).and_return("")
          expect(git_transaction.send(:writable?)).to be false
        end

        it "returns false when repository has no credentials" do
          allow(remote).to receive(:url).and_return("https://example.com/repo.git")
          expect(git_transaction.send(:writable?)).to be false
        end

        it "returns false when index is not writable" do
          allow(index).to receive(:writable?).and_return(false)
          expect(git_transaction.send(:writable?)).to be false
        end
      end

      describe "#merge_with_retries" do
        let(:default_branch) { "main" }
        let(:t_branch) { "tx/test-branch" }
        let(:branch) { double("branch", delete: nil) }

        before do
          allow(git).to receive(:checkout)
          allow(git).to receive(:merge)
          allow(git).to receive(:reset_hard)
          allow(git).to receive(:branch).with(t_branch).and_return(branch)
          allow(git_transaction).to receive(:default_branch).and_return(default_branch)
        end

        it "merges successfully on first try" do
          expect(git).to receive(:checkout).with(default_branch)
          expect(git).to receive(:merge).with(t_branch, "merge #{t_branch}")
          expect(branch).to receive(:delete)

          git_transaction.send(:merge_with_retries, t_branch)
        end

        it "retries on Git::Error up to MAX_RETRIES times" do
          allow(git).to receive(:merge).and_raise(Git::Error.new("merge conflict"))
          allow(git_transaction).to receive(:sleep)

          expect(git).to receive(:merge).exactly(4).times # 1 initial + 3 retries
          expect(git).to receive(:reset_hard).exactly(3).times
          expect do
            git_transaction.send(:merge_with_retries, t_branch)
          end.to raise_error(Git::Error, "merge conflict")
        end

        it "raises error after MAX_RETRIES" do
          allow(git).to receive(:merge).and_raise(Git::Error.new("persistent error"))
          allow(git_transaction).to receive(:sleep)

          expect do
            git_transaction.send(:merge_with_retries, t_branch)
          end.to raise_error(Git::Error, "persistent error")
        end
      end

      describe "#push_with_retries" do
        let(:remote) { "origin" }
        let(:default_branch) { "main" }
        let(:push_opts) { { force: true } }

        before do
          allow(git).to receive(:push)
          allow(git).to receive(:pull)
          allow(git).to receive(:rebase)
          allow(git_transaction).to receive(:default_branch).and_return(default_branch)
        end

        it "pushes successfully on first try" do
          expect(git).to receive(:push).with(remote, default_branch, **push_opts)

          git_transaction.send(:push_with_retries, remote, push_opts)
        end

        it "retries with pull/rebase on Git::Error" do
          allow(git).to receive(:push).and_raise(Git::Error.new("push failed"))
          allow(git_transaction).to receive(:sleep)

          expect(git).to receive(:push).exactly(4).times # 1 initial + 3 retries
          expect(git).to receive(:pull).exactly(3).times
          expect(git).to receive(:rebase).exactly(3).times

          expect do
            git_transaction.send(:push_with_retries, remote, push_opts)
          end.to raise_error(Git::Error, "push failed")
        end

        it "raises error after MAX_RETRIES" do
          allow(git).to receive(:push).and_raise(Git::Error.new("persistent push error"))
          allow(git).to receive(:pull)
          allow(git).to receive(:rebase)
          allow(git_transaction).to receive(:sleep)

          expect do
            git_transaction.send(:push_with_retries, remote, push_opts)
          end.to raise_error(Git::Error, "persistent push error")
        end
      end

      describe "#with_timeout" do
        it "executes block without timeout when seconds is nil" do
          expect(Timeout).not_to receive(:timeout)
          git_transaction.send(:with_timeout, nil) { "result" }
        end

        it "executes block without timeout when seconds is 0" do
          expect(Timeout).not_to receive(:timeout)
          git_transaction.send(:with_timeout, 0) { "result" }
        end

        it "executes block with timeout when seconds is positive" do
          expect(Timeout).to receive(:timeout).with(30, Git::Error)
          git_transaction.send(:with_timeout, 30) { "result" }
        end
      end

      describe "#default_branch" do
        it "returns the main branch name" do
          expect(git_transaction.send(:default_branch)).to eq("main")
        end

        it "creates a new branch when no main branch found" do
          allow(Decidim::CommunityTemplates).to receive(:git_settings).and_return({ branch: "nonexistent" })
          allow(git).to receive(:checkout) do |_branch, options|
            raise Git::Error, "branch not found" unless options
          end
          allow(git).to receive(:current_branch).and_return("main")
          expect(git_transaction.send(:default_branch)).to eq("nonexistent")
          expect(git).to have_received(:checkout).with("nonexistent", new_branch: true)
        end
      end

      describe "#assert_head_on!" do
        let(:branch) { "main" }

        before do
          allow(git).to receive(:current_branch).and_return(branch)
        end

        it "does not raise when HEAD is on the specified branch" do
          expect do
            git_transaction.send(:assert_head_on!, branch)
          end.not_to raise_error
        end

        it "raises Git::Error when HEAD is not on the specified branch" do
          allow(git).to receive(:current_branch).and_return("feature")

          expect do
            git_transaction.send(:assert_head_on!, branch)
          end.to raise_error(Git::Error, 'HEAD not on "main" (at "feature")')
        end
      end

      describe "#safe_checkout" do
        let(:branch) { "main" }

        before do
          allow(git).to receive(:checkout)
          allow(git).to receive(:reset_hard)
          allow(git).to receive(:branches).and_return(double("branches", local: [double("branch", name: branch)]))
        end

        it "checks out branch successfully" do
          expect(git).to receive(:checkout).with(branch)
          git_transaction.send(:safe_checkout, branch)
        end

        it "resets hard and checks out on Git::Error" do
          allow(git).to receive(:checkout).with(branch).and_raise(Git::Error.new("checkout failed"))
          expect(git).to receive(:reset_hard).with(branch)
          expect(git).to receive(:checkout).with(branch).twice
          expect do
            git_transaction.send(:safe_checkout, branch)
          end.to raise_error(Git::Error, "checkout failed")
        end
      end

      describe "#safe_delete_branch" do
        let(:branch_name) { "feature-branch" }
        let(:branch) { double("branch", delete: nil) }

        before do
          allow(git).to receive(:branch).with(branch_name).and_return(branch)
          allow(git).to receive(:local_branch?)
        end

        it "deletes branch when it exists locally" do
          allow(git).to receive(:local_branch?).with(branch_name).and_return(true)
          expect(branch).to receive(:delete)

          git_transaction.send(:safe_delete_branch, branch_name)
        end

        it "does nothing when branch does not exist locally" do
          allow(git).to receive(:local_branch?).with(branch_name).and_return(false)
          expect(branch).not_to receive(:delete)

          git_transaction.send(:safe_delete_branch, branch_name)
        end

        it "ignores Git::Error when deleting branch" do
          allow(git).to receive(:local_branch?).with(branch_name).and_return(true)
          allow(branch).to receive(:delete).and_raise(Git::Error.new("delete failed"))

          expect do
            git_transaction.send(:safe_delete_branch, branch_name)
          end.not_to raise_error
        end
      end

      describe "#dirty?" do
        let(:status) { double("status") }

        before do
          allow(git).to receive(:status).and_return(status)
        end

        it "returns true when there are changed files" do
          allow(status).to receive(:changed).and_return(["file1.txt"])
          allow(status).to receive(:added).and_return([])
          allow(status).to receive(:deleted).and_return([])
          allow(status).to receive(:untracked).and_return([])

          expect(git_transaction.send(:dirty?)).to be true
        end

        it "returns true when there are added files" do
          allow(status).to receive(:changed).and_return([])
          allow(status).to receive(:added).and_return(["file2.txt"])
          allow(status).to receive(:deleted).and_return([])
          allow(status).to receive(:untracked).and_return([])

          expect(git_transaction.send(:dirty?)).to be true
        end

        it "returns true when there are deleted files" do
          allow(status).to receive(:changed).and_return([])
          allow(status).to receive(:added).and_return([])
          allow(status).to receive(:deleted).and_return(["file3.txt"])
          allow(status).to receive(:untracked).and_return([])

          expect(git_transaction.send(:dirty?)).to be true
        end

        it "returns true when there are untracked files" do
          allow(status).to receive(:changed).and_return([])
          allow(status).to receive(:added).and_return([])
          allow(status).to receive(:deleted).and_return([])
          allow(status).to receive(:untracked).and_return(["file4.txt"])

          expect(git_transaction.send(:dirty?)).to be true
        end

        it "returns false when repository is clean" do
          allow(status).to receive(:changed).and_return([])
          allow(status).to receive(:added).and_return([])
          allow(status).to receive(:deleted).and_return([])
          allow(status).to receive(:untracked).and_return([])

          expect(git_transaction.send(:dirty?)).to be false
        end

        it "returns true when Git::Error occurs" do
          allow(git).to receive(:status).and_raise(Git::Error.new("status failed"))

          expect(git_transaction.send(:dirty?)).to be true
        end
      end

      describe "file locking" do
        let(:lockfile) { ".git/git-debate.lock" }

        before do
          allow(git_transaction).to receive(:dirty?).and_return(false)
          allow(git_transaction).to receive(:writable?).and_return(true)
          allow(git_transaction).to receive(:default_branch).and_return(default_branch)
          allow(git_transaction).to receive(:assert_head_on!)
          allow(git_transaction).to receive(:merge_with_retries)
          allow(git_transaction).to receive(:push_with_retries)
        end

        it "creates and locks the lockfile during execution" do
          expect(File).to receive(:open).with(lockfile, File::RDWR | File::CREAT, 0o644).and_call_original

          git_transaction.perform(remote: "origin", push_opts: {}) do
            # do nothing
          end
        end

        it "unlocks the file after execution" do
          file_double = double("file")
          allow(File).to receive(:open).and_yield(file_double)
          expect(file_double).to receive(:flock).with(File::LOCK_EX)
          expect(file_double).to receive(:flock).with(File::LOCK_UN)

          git_transaction.perform(remote: "origin", push_opts: {}) do
            # do nothing
          end
        end
      end
    end
  end
end
