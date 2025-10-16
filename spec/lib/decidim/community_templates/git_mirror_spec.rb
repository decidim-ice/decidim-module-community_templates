# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    describe GitMirror do
      let(:git_mirror) { described_class.instance }
      let(:catalog_path) { Rails.root.join("tmp", "catalogs", "test_catalog_#{SecureRandom.hex(8)}") }
      let(:git_settings) { build(:git_settings) }
      let(:git_instance) { create(:git, path: catalog_path) }

      before do
        # Reset singleton instance
        git_mirror.instance_variable_set(:@configured, false)
        git_mirror.instance_variable_set(:@errors, ActiveModel::Errors.new(git_mirror))
        git_mirror.catalog_path = catalog_path
        git_mirror.settings = git_settings
      end

      after do
        FileUtils.rm_rf(catalog_path) if catalog_path.exist?
      end

      describe "#configured?" do
        it "returns false by default" do
          expect(git_mirror.configured?).to be false
        end

        it "returns true after configuration" do
          git_mirror.configure({})
          expect(git_mirror.configured?).to be true
        end
      end

      describe "#configure" do
        it "configures the mirror with given options" do
          options = { repo_url: "https://example.com/repo.git" }
          result = git_mirror.configure(options)

          expect(git_mirror.settings.repo_url).to eq("https://example.com/repo.git")
          expect(git_mirror.configured?).to be true
          expect(result).to eq(git_mirror)
        end

        it "assigns attributes to settings" do
          options = { repo_branch: "develop", repo_username: "user" }
          expect(git_mirror.settings).to receive(:assign_attributes).with(options)

          git_mirror.configure(options)
        end
      end

      describe "#valid?" do
        before do
          allow(git_mirror.settings).to receive(:valid?).and_return(true)
        end

        it "returns true when both mirror and settings are valid" do
          allow(git_mirror).to receive(:validate).and_return(true)
          expect(git_mirror.valid?).to be true
        end

        it "returns false when mirror validation fails" do
          allow(git_mirror).to receive(:validate).and_return(false)
          git_mirror.errors.add(:base, "Mirror error")
          expect(git_mirror.valid?).to be false
        end

        it "returns false when settings validation fails" do
          allow(git_mirror).to receive(:validate).and_return(true)
          allow(git_mirror.settings).to receive(:valid?).and_return(false)
          expect(git_mirror.valid?).to be false
        end
      end

      describe "#validate" do
        context "when catalog path does not exist" do
          before do
            allow(catalog_path).to receive(:exist?).and_return(false)
          end

          it "adds error about missing catalog path" do
            git_mirror.validate(git_instance)
            expect(git_mirror.errors.full_messages).to include(match(/Repository catalog path does not exist/))
          end
        end

        context "when catalog path exists but is not a git repository" do
          before do
            allow(catalog_path).to receive(:exist?).and_return(true)
            allow(catalog_path).to receive(:join).with(".git").and_return(double(exist?: false))
          end

          it "adds error about not being a git repository" do
            git_mirror.validate(git_instance)
            expect(git_mirror.errors.full_messages).to include(match(/Repository catalog path is not a git repository/))
          end
        end

        context "when catalog path is valid" do
          before do
            allow(catalog_path).to receive(:exist?).and_return(true)
            allow(catalog_path).to receive(:join).with(".git").and_return(double(exist?: true))
          end

          it "does not add any errors" do
            git_mirror.validate(git_instance)
            expect(git_mirror.errors).to be_empty
          end
        end
      end

      describe "#validate!" do
        before do
          allow(git_mirror.settings).to receive(:validate).and_return(true)
          allow(git_mirror).to receive(:validate).and_return(true)
        end

        it "validates settings and mirror" do
          expect(git_mirror.settings).to receive(:validate)
          expect(git_mirror).to receive(:validate).with(git_instance)

          git_mirror.validate!(git_instance)
        end

        it "raises GitError when validation fails" do
          allow(git_mirror.settings).to receive(:validate).and_return(false)
          allow(git_mirror.settings.errors).to receive(:full_messages).and_return(["Settings error"])

          expect do
            git_mirror.validate!(git_instance)
          end.to raise_error(GitError, "Settings error")
        end

        it "raises GitError when mirror validation fails" do
          allow(git_mirror).to receive(:validate).and_return(false)
          git_mirror.errors.add(:base, "Mirror error")

          expect do
            git_mirror.validate!(git_instance)
          end.to raise_error(GitError, "Mirror error")
        end
      end

      describe "#empty?" do
        context "when catalog path does not exist" do
          before do
            allow(catalog_path).to receive(:exist?).and_return(false)
          end

          it "returns true" do
            expect(git_mirror.empty?(git_instance)).to be true
          end
        end

        context "when .git directory does not exist" do
          before do
            allow(catalog_path).to receive(:exist?).and_return(true)
            allow(catalog_path).to receive(:join).with(".git").and_return(double(exist?: false))
          end

          it "returns true" do
            expect(git_mirror.empty?(git_instance)).to be true
          end
        end
      end

      describe "#templates_count" do
        let(:uuid1) { SecureRandom.uuid }
        let(:uuid2) { SecureRandom.uuid }
        let(:non_uuid) { "not-a-uuid" }

        before do
          allow(catalog_path).to receive(:children).and_return([
                                                                 double(directory?: true, basename: double(to_s: uuid1)),
                                                                 double(directory?: true, basename: double(to_s: uuid2)),
                                                                 double(directory?: true, basename: double(to_s: non_uuid)),
                                                                 double(directory?: false, basename: double(to_s: uuid1))
                                                               ])
        end

        it "counts only directories with UUID names" do
          expect(git_mirror.templates_count).to eq(2)
        end
      end

      describe "#open_git" do
        before do
          allow(catalog_path).to receive(:join).with(".git").and_return(double(exist?: true))
        end

        it "opens git repository" do
          allow(Git).to receive(:open).with(catalog_path, log: Rails.logger).and_return(git_instance)
          expect(git_mirror.open_git).to eq(git_instance)
        end

        context "when ArgumentError is raised" do
          before do
            allow(Git).to receive(:open).and_raise(ArgumentError.new("not a git repository"))
          end

          it "raises Git::Error when .git directory exists" do
            expect do
              git_mirror.open_git
            end.to raise_error(Git::Error, "not a git repository")
          end

          it "logs ownership issues" do
            allow(catalog_path).to receive(:join).with(".git").and_return(double(exist?: true))
            allow(git_mirror).to receive(:`).and_return("fatal: detected dubious ownership")

            expect(Rails.logger).to receive(:error).with(match(/Git repository has ownership issues/))
            expect do
              git_mirror.open_git
            end.to raise_error(Git::Error)
          end

          it "logs not a git repository error" do
            allow(catalog_path).to receive(:join).with(".git").and_return(double(exist?: true))
            allow(git_mirror).to receive(:`).and_return("fatal: not a git repository")

            expect(Rails.logger).to receive(:error).with(match(/Directory is not a valid git repository/))
            expect do
              git_mirror.open_git
            end.to raise_error(Git::Error)
          end
        end
      end

      describe "#last_commit" do
        let(:commit_sha) { "abc123def456" }
        let(:log) { double(execute: [double(sha: commit_sha)]) }

        before do
          allow(git_instance).to receive(:log).with(1).and_return(log)
        end

        it "returns the last commit SHA" do
          allow(GitTransaction).to receive(:perform).and_yield(git_instance)

          expect(git_mirror.last_commit).to eq(commit_sha)
        end
      end

      describe "#transaction" do
        before do
          git_mirror.configure({})
        end

        it "raises GitError when not configured" do
          git_mirror.instance_variable_set(:@configured, false)
          expect do
            git_mirror.transaction do
              # do nothing
            end
          end.to raise_error(GitError, "Git mirror not configured")
        end

        it "executes block within transaction when configured" do
          # Mock the open_git method to return our test git instance
          allow(git_mirror).to receive(:open_git).and_return(git_instance)

          # Mock the with_git_credentials method to yield the git instance
          allow(git_mirror).to receive(:with_git_credentials).with(git_instance).and_yield(git_instance)

          # Mock GitTransaction.perform to yield the git instance
          allow(GitTransaction).to receive(:perform).with(git_instance).and_yield(git_instance)

          # Mock validate! to avoid actual validation
          allow(git_mirror).to receive(:validate!).with(git_instance)

          # Execute the transaction
          git_mirror.transaction do |git|
            expect(git).to eq(git_instance)
          end
        end
      end

      describe "#pull!" do
        before do
          git_mirror.configure({})
        end

        it "raises GitError when not configured" do
          git_mirror.instance_variable_set(:@configured, false)
          expect do
            git_mirror.pull!
          end.to raise_error(GitError, "Git mirror not configured")
        end
      end

      describe "#with_git_credentials" do
        let(:repo_url) { "https://user:pass@example.com/repo.git" }
        let(:authenticated_url) { "https://user:pass@example.com/repo.git" }

        before do
          git_mirror.settings.repo_url = repo_url
          git_mirror.settings.repo_username = "user"
          git_mirror.settings.repo_password = "pass"
        end

        it "parses and validates URI" do
          expect(git_mirror).to receive(:ensure_remote_origin).with(git_instance, authenticated_url)
          expect(git_mirror).to receive(:configure_pull_strategy).with(git_instance)
          expect(git_mirror).to receive(:ensure_unauthenticated_remote).with(git_instance)

          git_mirror.send(:with_git_credentials, git_instance) do |git|
            expect(git).to eq(git_instance)
          end
        end

        it "raises GitError for invalid URI" do
          git_mirror.settings.repo_url = "invalid-url"

          expect do
            git_mirror.send(:with_git_credentials, git_instance) do
              # do nothing
            end
          end.to raise_error(GitError, /Invalid repository URL/)
        end

        it "handles Git::Error during execution" do
          allow(git_mirror).to receive(:ensure_remote_origin).and_raise(Git::Error.new("git error"))

          expect do
            git_mirror.send(:with_git_credentials, git_instance) do
              # do nothing
            end
          end.to raise_error(GitError, "Git operation failed: git error")
        end

        it "handles StandardError during execution" do
          allow(git_mirror).to receive(:ensure_remote_origin).and_raise(StandardError.new("unexpected error"))

          expect do
            git_mirror.send(:with_git_credentials, git_instance) do
              # do nothing
            end
          end.to raise_error(GitError, "Git operation failed: unexpected error")
        end
      end

      describe "#ensure_remote_origin" do
        let(:remote_url) { "https://example.com/repo.git" }
        let(:remote) { double("remote") }

        before do
          allow(git_instance).to receive(:remotes).and_return([remote])
          allow(remote).to receive(:name).and_return("origin")
        end

        it "adds remote when origin does not exist" do
          allow(git_mirror).to receive(:has_origin?).with(git_instance).and_return(false)
          expect(git_instance).to receive(:add_remote).with("origin", remote_url)

          git_mirror.send(:ensure_remote_origin, git_instance, remote_url)
        end

        it "updates remote when origin exists with different URL" do
          allow(git_mirror).to receive(:has_origin?).with(git_instance).and_return(true)
          allow(git_mirror).to receive(:get_remote_url).with(git_instance, "origin").and_return("https://old.com/repo.git")
          allow(git_mirror).to receive(:remove_remote_safely).with(git_instance, "origin").and_return(true)
          expect(git_instance).to receive(:add_remote).with("origin", remote_url)

          git_mirror.send(:ensure_remote_origin, git_instance, remote_url)
        end

        it "does nothing when origin exists with same URL" do
          allow(git_mirror).to receive(:has_origin?).with(git_instance).and_return(true)
          allow(git_mirror).to receive(:get_remote_url).with(git_instance, "origin").and_return(remote_url)

          expect(git_instance).not_to receive(:add_remote)
          git_mirror.send(:ensure_remote_origin, git_instance, remote_url)
        end
      end

      describe "#has_origin?" do
        let(:remote) { double("remote", name: "origin") }

        it "returns true when origin remote exists" do
          allow(git_instance).to receive(:remotes).and_return([remote])
          expect(git_mirror.send(:has_origin?, git_instance)).to be true
        end

        it "returns false when origin remote does not exist" do
          allow(git_instance).to receive(:remotes).and_return([])
          expect(git_mirror.send(:has_origin?, git_instance)).to be false
        end

        it "returns false when git does not respond to remotes" do
          allow(git_instance).to receive(:respond_to?).with(:remotes).and_return(false)
          expect(git_mirror.send(:has_origin?, git_instance)).to be false
        end

        it "handles StandardError gracefully" do
          allow(git_instance).to receive(:remotes).and_raise(StandardError.new("error"))
          expect(git_mirror.send(:has_origin?, git_instance)).to be false
        end
      end

      describe "#get_remote_url" do
        let(:remote) { double("remote", url: "https://example.com/repo.git") }

        it "returns remote URL when remote exists" do
          allow(git_instance).to receive(:remote).with("origin").and_return(remote)
          expect(git_mirror.send(:get_remote_url, git_instance, "origin")).to eq("https://example.com/repo.git")
        end

        it "returns nil when remote does not exist" do
          allow(git_instance).to receive(:remote).with("origin").and_return(nil)
          expect(git_mirror.send(:get_remote_url, git_instance, "origin")).to be_nil
        end

        it "handles StandardError gracefully" do
          allow(git_instance).to receive(:remote).and_raise(StandardError.new("error"))
          expect(git_mirror.send(:get_remote_url, git_instance, "origin")).to be_nil
        end
      end

      describe "#remove_remote_safely" do
        let(:remote) { double("remote") }

        it "removes remote when it exists" do
          allow(git_instance).to receive(:remote).with("origin").and_return(remote)
          allow(remote).to receive(:respond_to?).with(:remove).and_return(true)
          allow(remote).to receive(:remove)
          allow(git_mirror).to receive(:has_origin?).with(git_instance).and_return(false)

          expect(git_mirror.send(:remove_remote_safely, git_instance, "origin")).to be true
        end

        it "returns true when remote does not exist" do
          allow(git_instance).to receive(:remote).with("origin").and_return(nil)
          expect(git_mirror.send(:remove_remote_safely, git_instance, "origin")).to be true
        end

        it "handles StandardError gracefully" do
          allow(git_instance).to receive(:remote).and_raise(StandardError.new("error"))
          expect(git_mirror.send(:remove_remote_safely, git_instance, "origin")).to be false
        end
      end

      describe "#configure_pull_strategy" do
        it "configures git pull strategy" do
          expect(git_instance).to receive(:config).with("pull.rebase", "true")
          git_mirror.send(:configure_pull_strategy, git_instance)
        end

        it "handles StandardError gracefully" do
          allow(git_instance).to receive(:config).and_raise(StandardError.new("error"))
          expect(Rails.logger).to receive(:warn).with("Failed to configure pull strategy: error")
          git_mirror.send(:configure_pull_strategy, git_instance)
        end
      end

      describe "#ensure_unauthenticated_remote" do
        let(:repo_url) { "https://example.com/repo.git" }

        before do
          git_mirror.settings.repo_url = repo_url
        end

        it "removes and re-adds remote without credentials" do
          allow(git_mirror).to receive(:has_origin?).with(git_instance).and_return(true)
          allow(git_instance).to receive(:remove_remote).with("origin")
          expect(git_instance).to receive(:add_remote).with("origin", repo_url)

          git_mirror.send(:ensure_unauthenticated_remote, git_instance)
        end

        it "handles errors gracefully" do
          allow(git_instance).to receive(:remove_remote).and_raise(StandardError.new("error"))
          expect(Rails.logger).to receive(:warn).with(match(/Unexpected error resetting remote origin/))

          git_mirror.send(:ensure_unauthenticated_remote, git_instance)
        end
      end

      describe "delegation" do
        it "delegates settings methods" do
          expect(git_mirror.repo_url).to eq(git_settings.repo_url)
          expect(git_mirror.repo_branch).to eq(git_settings.repo_branch)
          expect(git_mirror.repo_username).to eq(git_settings.repo_username)
          expect(git_mirror.repo_password).to eq(git_settings.repo_password)
          expect(git_mirror.repo_author_name).to eq(git_settings.repo_author_name)
          expect(git_mirror.repo_author_email).to eq(git_settings.repo_author_email)
        end
      end
    end
  end
end
