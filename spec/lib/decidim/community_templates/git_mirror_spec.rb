# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitMirror do
      describe "#valid?" do
        it "returns false if the repository is not cloned" do
          git_mirror = create(:git_mirror, :empty)
          FileUtils.rm_rf(git_mirror.catalog_path)
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/catalog path does not exist/))
        end

        it "returns false if the repository is cloned and but have no commits" do
          git_mirror = create(:git_mirror, :with_unstaged_file)
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/Repository is empty/))
        end

        it "returns true if the repository is cloned and not empty" do
          git_mirror = create(:git_mirror, :with_commit)
          expect(git_mirror).to be_valid
        end
      end

      describe "#empty?" do
        it "returns true if the catalog path does not exists" do
          git_mirror = create(:git_mirror)
          expect(git_mirror).to be_empty
        end

        it "returns true if the catalog path exists but is not a git repository" do
          git_mirror = create(:git_mirror)
          FileUtils.mkdir_p(git_mirror.catalog_path)
          expect(git_mirror).to be_empty
        end

        it "returns true if the catalog path exists and is a git repository but does not have any commits" do
          git_mirror = create(:git_mirror)
          Git.init(git_mirror.catalog_path)
          expect(git_mirror).to be_empty
        end

        it "returns false if the catalog path exists and is a git repository and has commits" do
          git_mirror = create(:git_mirror, :with_commit)
          expect(git_mirror).not_to be_empty
        end
      end

      describe "#git" do
        it "returns a new Git::Base instance" do
          git_mirror = create(:git_mirror, :with_commit)
          git1 = git_mirror.git
          git2 = git_mirror.git
          expect(git1).not_to eq(git2)
          expect(git1).to be_a(Git::Base)
        end

        it "raises ArgumentError if the catalog path does not exist" do
          git_mirror = create(:git_mirror)
          git_mirror.catalog_path.rmtree
          expect { git_mirror.git }.to raise_error(ArgumentError)
        end

        it "if git has a dubidious ownership error, it raises a GitError and advises to add safe.directory in git config" do
          git_mirror = create(:git_mirror, :with_commit)
          allow(Rails.logger).to receive(:error)
          allow(Git).to receive(:open).and_raise(ArgumentError.new("fatal: not a git repository"))
          # In case of a dubious ownership error, ruby-git raises an ArgumentError with a message like:
          # "fatal: not a git repository (or any of the parent directories): .git"
          # So system should do a git status and check for dubious ownership
          allow(git_mirror).to receive(:`).with("cd #{git_mirror.catalog_path} && git status 2>&1").and_return("dubious ownership")

          expect { git_mirror.git }.to raise_error(GitError)
          # Advise the user about this classic issue in docker environments
          expect(Rails.logger).to have_received(:error).with(match("--add safe.directory #{git_mirror.catalog_path}"))
        end
      end

      describe "#configure" do
        it "sets the repo_url" do
          git_mirror = create(:git_mirror)
          git_mirror.configure(repo_url: "https://github.com/decidim/decidim.git")
          expect(git_mirror.repo_url).to eq("https://github.com/decidim/decidim.git")
        end

        it "sets the repo_branch" do
          git_mirror = create(:git_mirror)
          git_mirror.configure(repo_branch: "main")
          expect(git_mirror.repo_branch).to eq("main")
        end
      end

      describe "#validate!" do
        it "raises a GitError if validation have any errors" do
          git_mirror = create(:git_mirror)
          git_mirror.errors.add(:base, "test error")
          expect { git_mirror.validate! }.to raise_error(GitError)
        end
      end

      describe "#writable?" do
        it "returns false if repo_username and repo_password are not set" do
          git_mirror = create(:git_mirror, :with_commit, settings_attributes: { repo_username: "", repo_password: "" })
          expect(git_mirror).not_to be_writable
        end

        it "returns false if git index is not writable" do
          git_mirror = create(:git_mirror, :with_commit)
          git_instance = git_mirror.git
          allow(git_mirror).to receive(:git).and_return(git_instance)
          allow(git_instance.index).to receive(:writable?).and_return(false)
          expect(git_mirror).not_to be_writable
        end
      end

      describe "#push!" do
        it "raises a RuntimeError if the repository is not writable" do
          git_mirror = create(:git_mirror, :with_commit, settings_attributes: { repo_username: "", repo_password: "" })
          expect { git_mirror.push! }.to raise_error(RuntimeError)
        end

        context "when there are changes to push" do
          let(:git_mirror) { create(:git_mirror, :with_commit) }
          let(:git_instance) { git_mirror.git }

          before do
            allow(git_mirror).to receive(:git).and_return(git_instance)
            allow(git_mirror).to receive(:with_git_credentials).and_yield(git_instance)
            allow(git_instance).to receive(:push).and_return(true)
            allow(git_instance).to receive(:remote).and_return(double("remote", fetch: true, url: nil))
            FileUtils.touch(git_mirror.catalog_path.join("test.txt"))
          end

          it "reset previous changes and creates a unique commit" do
            git_mirror.push!
            expect(git_mirror.git.log(1).execute.last.message).to include(":tada")
          end

          it "pushes the repository" do
            git_mirror.push!
            expect(git_instance).to have_received(:push).with("origin", git_mirror.repo_branch, force: true)
          end
        end

        context "when there are no changes to push" do
          let(:git_mirror) { create(:git_mirror, :with_commit) }
          let(:git_instance) { git_mirror.git }

          before do
            allow(git_mirror).to receive(:git).and_return(git_instance)
            allow(git_instance).to receive(:push)
            allow(git_instance).to receive(:remote).and_return(double("remote", fetch: true))
            allow(git_instance).to receive(:remotes).and_return([])
            allow(git_instance).to receive(:add_remote)
            git_status_instance = git_instance.status
            allow(git_instance).to receive(:status).and_return(git_status_instance)
            allow(git_status_instance).to receive(:any?).and_return(false)
            allow(git_status_instance).to receive(:changes).and_return(double("changes", empty?: true, any?: false))
          end

          it "does not create commit" do
            git_mirror.push!
            expect(git_mirror.git.log(1).execute.last.message).not_to include("Update community templates")
          end

          it "push the repository anyway" do
            expect { git_mirror.push! }.not_to raise_error
            expect(git_instance).to have_received(:push)
          end
        end
      end

      describe "#pull" do
        context "when the repository is writable" do
          it "push the repository if there are changes" do
            git_mirror = create(:git_mirror, :with_commit)
            git_instance = git_mirror.git
            allow(git_mirror).to receive(:git).and_return(git_instance)
            allow(git_mirror).to receive(:writable?).and_return(true)
            allow(git_instance).to receive(:pull)
            allow(git_instance).to receive(:push)
            allow(git_instance).to receive(:remotes).and_return([])
            allow(git_instance).to receive(:add_remote)
            remote_double = double("remote")
            allow(remote_double).to receive(:fetch)
            allow(git_instance).to receive(:remote).and_return(remote_double)

            git_mirror.pull
            expect(git_instance).to have_received(:push)
          end

          it "raises a GitError if repo is badly configured" do
            git_mirror = create(:git_mirror, :with_commit, settings_attributes: { repo_username: "", repo_password: "apasswordwithout-username" })
            git_instance = git_mirror.git
            allow(git_mirror).to receive(:git).and_return(git_instance)
            allow(git_mirror).to receive(:writable?).and_return(true)
            allow(git_instance).to receive(:pull)
            allow(git_instance).to receive(:remotes).and_return([])
            allow(git_instance).to receive(:add_remote)
            remote_double = double("remote")
            allow(remote_double).to receive(:fetch)
            allow(git_instance).to receive(:remote).and_return(remote_double)

            expect { git_mirror.pull }.to raise_error(GitError)
          end
        end

        context "when the repository is not writable" do
          it "it ignores unstaged changes and pull the repository" do
            git_mirror = create(:git_mirror, :with_commit)
            git_instance = git_mirror.git
            allow(git_mirror).to receive(:git).and_return(git_instance)
            allow(git_mirror).to receive(:writable?).and_return(false)
            allow(git_instance).to receive(:pull)
            allow(git_instance).to receive(:remotes).and_return([])
            allow(git_instance).to receive(:add_remote)
            remote_double = double("remote")
            allow(remote_double).to receive(:fetch)
            allow(git_instance).to receive(:remote).and_return(remote_double)

            git_mirror.pull
            expect(git_instance).to have_received(:pull)
          end
        end

        describe "when in the wrong branch," do
          let(:git_mirror) { create(:git_mirror, :with_commit) }
          let(:git_instance) do
            g_instance = git_mirror.git
            g_instance.checkout("wrong-branch", new_branch: true)
            allow(git_mirror).to receive(:git).and_return(g_instance)
            allow(g_instance).to receive(:fetch)
            allow(g_instance).to receive(:pull)
            allow(g_instance).to receive(:push)
            allow(g_instance).to receive(:checkout)
            allow(g_instance).to receive(:remotes).and_return([])
            allow(g_instance).to receive(:add_remote)
            remote_double = double("remote")
            allow(remote_double).to receive(:fetch)
            allow(g_instance).to receive(:remote).and_return(remote_double)

            g_instance
          end

          describe "and main branch exists" do
            it "checkout main branch" do
              main_branch_double = double("branch", name: "origin/main")
              wrong_branch_double = double("branch", name: "origin/wrong-branch")
              branches_double = double("branches", remote: [main_branch_double, wrong_branch_double], local: [main_branch_double, wrong_branch_double])
              def branches_double.[](index)
                remote[index]
              end
              allow(git_instance).to receive(:branches).and_return(branches_double)

              git_mirror.pull
              expect(git_instance).to have_received(:checkout).with("main", new_branch: false)
            end
          end

          describe "and main branch does not exist" do
            it "create a new main branch" do
              branches_double = double("branches", remote: [double("branch", name: "origin/wrong-branch")], local: [double("branch", name: "origin/local-wrong-branch")])
              def branches_double.[](index)
                remote[index]
              end
              allow(git_instance).to receive(:branches).and_return(branches_double)

              git_mirror.pull
              expect(git_instance).to have_received(:checkout).with("main", new_branch: true)
            end
          end
        end

        it "pulls the repository" do
          git_mirror = create(:git_mirror, :with_commit)
          git_instance = git_mirror.git
          allow(git_mirror).to receive(:git).and_return(git_instance)
          allow(git_instance).to receive(:fetch)
          allow(git_instance).to receive(:fetch)
          allow(git_instance).to receive(:push).and_return(true)
          allow(git_instance).to receive(:pull).and_return(true)
          allow(git_instance).to receive(:remotes).and_return([])
          allow(git_instance).to receive(:add_remote)
          remote_double = double("remote")
          allow(remote_double).to receive(:fetch)
          allow(git_instance).to receive(:remote).and_return(remote_double)

          branches_double = double("branches", remote: [double("branch", name: "origin/main")])
          def branches_double.[](index)
            remote[index]
          end

          git_mirror.pull
          expect(git_instance).to have_received(:pull)
          # push the commit
          expect(git_instance).to have_received(:push)
        end

        it "if remote branch does not exists, push it before" do
          git_mirror = create(:git_mirror, :with_commit)
          git_instance = git_mirror.git
          allow(git_mirror).to receive(:git).and_return(git_instance)
          allow(git_instance).to receive(:push)
          allow(git_instance).to receive(:pull)
          allow(git_instance).to receive(:remotes).and_return([])
          allow(git_instance).to receive(:add_remote)
          remote_double = double("remote")
          allow(remote_double).to receive(:fetch)
          allow(git_instance).to receive(:remote).and_return(remote_double)
          branches_double = double("branches", remote: [])
          def branches_double.[](index)
            remote[index]
          end
          allow(git_instance).to receive(:branches).and_return(branches_double)

          git_mirror.pull

          expect(git_instance).to have_received(:push).with("origin", git_mirror.repo_branch)
        end
      end
    end
  end
end
