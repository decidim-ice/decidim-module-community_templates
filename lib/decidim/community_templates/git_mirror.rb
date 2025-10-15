# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class GitMirror
      include Singleton

      delegate :repo_url,
               :repo_branch,
               :repo_username,
               :repo_password,
               :repo_author_name,
               :repo_author_email,
               to: :settings

      attr_accessor :catalog_path, :settings
      attr_reader :errors

      def push!
        validate!
        raise "Repository is not writable" unless writable?

        with_git_credentials do |git|
          checkout_branch(git, repo_branch)

          git.remote("origin").fetch

          if remote_branch_exists?(git)
            local_changes = git.status.changed.any? || git.status.untracked.any?
            git.reset_hard("origin/#{repo_branch}")
            if local_changes
              git.add(all: true)
              git.commit_all("Update community templates")
            end
          end
          git.push("origin", repo_branch.to_s, force: true)
        end
      end

      def pull
        # If we are synced with a remote git repository, we need to push first.
        return if !git.status.changed.empty? && !writable?

        validate!
        with_git_credentials do |git|
          checkout_branch(git, repo_branch) if git.current_branch != repo_branch

          git.remote("origin").fetch
          setup_branch_tracking(git, repo_branch)
          git.push("origin", repo_branch) if writable? && (!remote_branch_exists?(git) || !git.status.changed.empty?)
          git.pull("origin", repo_branch)
        end
      end

      def last_commit
        git.log(1).execute.last.sha
      end

      ##
      # Check if the repository is writable:
      # - the username/password are set
      # - a dry push can be performed
      def writable?
        return false unless repo_username && repo_password && repo_username.present? && repo_password.present?

        with_git_credentials do |git|
          git.index.writable?
        end
      end

      def initialize
        @settings = GitSettings.new
        @errors = ActiveModel::Errors.new(self)
        @catalog_path = Decidim::CommunityTemplates.catalog_path
      end

      def configure(options)
        settings.assign_attributes(options)
        self
      end

      def valid?
        validate
        errors.empty? && settings.valid?
      end

      def validate!
        settings.validate && validate
        messages = errors.full_messages + settings.errors.full_messages
        raise GitError, messages.join(", ") unless messages.empty?
      end

      def validate
        errors.clear
        return errors.add(:base, "Repository catalog path does not exist. Check #{catalog_path}.") unless catalog_path.exist?
        return errors.add(:base, "Repository catalog path is not a git repository. Check #{catalog_path}.") unless catalog_path.join(".git").exist?
        return errors.add(:base, "Repository is empty (no commits found)") if empty?
        return errors.add(:base, "Repository is not readable") unless git.index.readable?
      end

      def empty?
        return true unless catalog_path.exist?
        return true unless catalog_path.join(".git").exist?

        git.log(1).execute
        false
      rescue Git::FailedError => e
        e.result.status.exitstatus == 128 && !!(e.result.stderr =~ /does not have any commits yet/)
      end

      def templates_count
        catalog_path.children.select do |child|
          child.directory? && child.basename.to_s.match?(Decidim::CommunityTemplates::TemplateMetadata::UUID_REGEX)
        end.size
      end

      def git
        Git.open(catalog_path, :log => Rails.logger)
      rescue ArgumentError => e
        raise e unless catalog_path.join(".git").exist?

        status_output = `cd #{catalog_path} && git status 2>&1`
        if status_output.include?("dubious ownership")
          Rails.logger.error("Git repository has ownership issues. Run: git config --global --add safe.directory #{catalog_path}")
        elsif status_output.include?("not a git repository") || status_output.include?("not in a git working tree")
          Rails.logger.error("Directory is not a valid git repository. Status: #{status_output}")
        else
          Rails.logger.error("Git error: #{e.message}. Status: #{status_output}")
        end
        raise GitError, e.message
      end

      private

      def checkout_branch(git, repo_branch)
        return if git.current_branch == repo_branch

        git.checkout(repo_branch, new_branch: git.branches.local.none? { |branch| branch.name == "origin/#{repo_branch}" })
      end

      def setup_branch_tracking(git, repo_branch)
        # Check if current branch is tracking the remote branch
        current_branch = git.current_branch
        return if git.branches[current_branch].tracking_branch == "origin/#{repo_branch}"

        # Set up tracking if the remote branch exists
        git.branches[current_branch].set_tracking_branch("origin/#{repo_branch}") if remote_branch_exists?(git)
      rescue StandardError => e
        Rails.logger.warn("Failed to set up branch tracking: #{e.message}")
        # Continue without tracking - the pull will still work with explicit remote/branch
      end

      def with_git_credentials
        return yield(git) if repo_url.blank?

        # Validate and parse URI first
        begin
          uri = URI.parse(repo_url)
          raise GitError, "Invalid repository URL: #{repo_url}" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        rescue URI::InvalidURIError => e
          raise GitError, "Invalid repository URL: #{e.message}"
        end

        # Add credentials to URI
        uri.user = repo_username if repo_username.present?
        uri.password = repo_password if repo_password.present?

        # Ensure we have a clean remote state
        ensure_remote_origin(git, uri.to_s)
        configure_pull_strategy(git)
        yield(git)
      rescue Git::Error => e
        Rails.logger.error("Git execution error: #{e.message}")
        raise GitError, "Git operation failed: #{e.message}"
      rescue StandardError => e
        Rails.logger.error("Unexpected error in git operations: #{e.message}")
        raise GitError, "Git operation failed: #{e.message}"
      end

      def configure_pull_strategy(git)
        # Set pull strategy to merge (default) to avoid warnings
        git.config("pull.rebase", "false")
      rescue StandardError => e
        Rails.logger.warn("Failed to configure pull strategy: #{e.message}")
      end

      def ensure_remote_origin(git, remote_url)
        # Check if origin already exists and has the correct URL
        if has_origin?(git)
          current_url = get_remote_url(git, "origin")
          if current_url == remote_url
            Rails.logger.debug("Remote origin already configured with correct URL")
            return
          end

          Rails.logger.debug { "Updating remote origin URL from #{current_url} to #{remote_url}" }
          raise "Could not remove remote origin" unless remove_remote_safely(git, "origin")
        end

        # Add the remote with the correct URL
        git.add_remote("origin", remote_url)
        Rails.logger.debug { "Added remote origin: #{remote_url}" }
      rescue Git::Error => e
        Rails.logger.error("Failed to configure remote origin: #{e.message}")
        raise GitError, "Failed to configure remote origin: #{e.message}"
      end

      def has_origin?(git)
        git.remotes.any? { |remote| remote.name == "origin" }
      rescue StandardError
        false
      end

      def get_remote_url(git, remote_name)
        remote = git.remote(remote_name)
        return nil unless remote

        remote.respond_to?(:url) ? remote.url : nil
      rescue StandardError
        nil
      end

      def remove_remote_safely(git, remote_name)
        remote = git.remote(remote_name)
        return true unless remote&.url

        remote.remove if remote.respond_to?(:remove)

        !has_origin?(git)
      rescue StandardError => e
        Rails.logger.warn("Failed to remove remote #{remote_name}: #{e.message}")
        false
      end

      def remote_branch_exists?(git)
        git.branches.remote.any? { |branch| branch.name == "origin/#{repo_branch}" }
      rescue StandardError
        false
      end
    end
  end
end
