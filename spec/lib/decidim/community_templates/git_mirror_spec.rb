# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitMirror do
      describe "#valid?" do
        it "returns false if the repository is not cloned" do
          git_mirror = create(:git_mirror, :empty)
          expect(git_mirror).not_to be_valid
          expect(git_mirror.errors.full_messages).to include(match(/catalog path does not exist/))
        end

        it "returns true if the repository is cloned and not empty" do
          git_mirror = create(:git_mirror, :ready)
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
          git_mirror = create(:git_mirror, :ready)
          expect(git_mirror).not_to be_empty
        end
      end

      describe "#git" do
        it "returns a new Git::Base instance" do
          git_mirror = create(:git_mirror, :ready)
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
          git_mirror = create(:git_mirror, :ready)
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
          git_mirror = create(:git_mirror, :ready, settings_attributes: { repo_username: "", repo_password: "" })
          expect(git_mirror).not_to be_writable
        end

        it "returns false if git index is not writable" do
          git_mirror = create(:git_mirror, :ready)
          mock_index = double("index", writable?: false)
          expect_any_instance_of(Git::Base).to receive(:index).and_return(mock_index) # rubocop:disable RSpec/AnyInstance, RSpec/StubbedMock
          expect(git_mirror).not_to be_writable
        end
      end

      describe "#push!" do
        it "raises a RuntimeError if the repository is not writable" do
          git_mirror = create(:git_mirror, :ready, settings_attributes: { repo_username: "", repo_password: "" })
          expect { git_mirror.push! }.to raise_error(RuntimeError)
        end

        it "pushes the repository" do
          git_mirror = create(:git_mirror, :ready)
          expect_any_instance_of(Git::Base).to receive(:push).with("origin", git_mirror.repo_branch, force: true).and_return(true) # rubocop:disable RSpec/AnyInstance, RSpec/StubbedMock
          git_mirror.push!
        end
      end

      describe "#pull" do
        it "raises a GitError if the repository is not valid" do
          git_mirror = create(:git_mirror, :ready, settings_attributes: { repo_username: "", repo_password: "apasswordwithout-username" })
          expect { git_mirror.pull }.to raise_error(GitError)
        end

        it "pulls the repository" do
          git_mirror = create(:git_mirror, :ready)
          expect_any_instance_of(Git::Base).to receive(:pull).with("origin", git_mirror.repo_branch).and_return(true) # rubocop:disable RSpec/AnyInstance, RSpec/StubbedMock
          git_mirror.pull
        end
      end
    end
  end
end
