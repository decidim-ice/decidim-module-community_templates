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

      attr_accessor :catalog_path, :settings, :configured
      attr_reader :errors

      def initialize
        @settings = GitSettings.new
        @errors = ActiveModel::Errors.new(self)
        @catalog_path = Decidim::CommunityTemplates.catalog_path
        @configured = false
      end

      def transaction
        raise GitError, "Git mirror not configured" unless configured?

        with_git_credentials(open_git) do |authenticated_git|
          GitTransaction.perform(authenticated_git) do |_git|
            validate!(authenticated_git)
            yield authenticated_git
          end
        end
      end

      def pull!
        raise GitError, "Git mirror not configured" unless configured?

        GitTransaction.perform(open_git) do |git|
          validate!(git)
          default_branch = git.branches.local.find { |b| b.name.ends_with?("main") }&.name || "main"
          git.pull("origin", default_branch)
        end
      end

      def configured?
        @configured
      end

      def configure(options)
        settings.assign_attributes(options)
        @configured = true
        self
      end

      def valid?
        validate
        errors.empty? && settings.valid?
      end

      def validate!(git)
        settings.validate && validate(git)
        messages = errors.full_messages + settings.errors.full_messages
        raise GitError, messages.join(", ") unless messages.empty?
      end

      def validate(_git)
        errors.clear
        return errors.add(:base, "Repository catalog path does not exist. Check #{catalog_path}.") unless catalog_path.exist?
        return errors.add(:base, "Repository catalog path is not a git repository. Check #{catalog_path}.") unless catalog_path.join(".git").exist?
      end

      def empty?(git)
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

      def open_git
        Git.open(catalog_path, :log => Rails.logger)
      rescue ArgumentError => e
        raise Git::Error, e.message unless catalog_path.join(".git").exist?

        status_output = `cd #{catalog_path} && git status 2>&1`
        if status_output.include?("dubious ownership")
          Rails.logger.error("Git repository has ownership issues. Run: git config --global --add safe.directory #{catalog_path}")
        elsif status_output.include?("not a git repository") || status_output.include?("not in a git working tree")
          Rails.logger.error("Directory is not a valid git repository. Status: #{status_output}")
        else
          Rails.logger.error("Git error: #{e.message}. Status: #{status_output}")
        end
        raise Git::Error, e.message
      end

      def last_commit
        GitTransaction.perform(open_git) do |git|
          git.log(1).execute.last.sha
        end
      end

      private

      # Validate and parse URI first
      def with_git_credentials(git)
        begin
          uri = URI.parse(repo_url)
          raise GitError, "Invalid repository URL: #{repo_url}" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        rescue URI::InvalidURIError => e
          Rails.logger.error("Invalid URI: #{e.message}")
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
        Rails.logger.error("Git error backtrace: #{e.backtrace.first(5).join("\n")}")
        raise GitError, "Git operation failed: #{e.message}"
      rescue StandardError => e
        Rails.logger.error("Unexpected error in git operations: #{e.message}")
        Rails.logger.error("Error class: #{e.class}")
        Rails.logger.error("Error backtrace: #{e.backtrace.first(10).join("\n")}")
        raise GitError, "Git operation failed: #{e.message}"
      ensure
        Rails.logger.debug("with_git_credentials: Calling ensure_unauthenticated_remote")
        ensure_unauthenticated_remote(git)
      end

      def ensure_unauthenticated_remote(git)
        begin
          uri = URI.parse(repo_url)
          raise GitError, "Invalid repository URL: #{repo_url}" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        rescue URI::InvalidURIError => e
          raise GitError, "Invalid repository URL: #{e.message}"
        end

        uri.user = nil
        uri.password = nil

        begin
          git.remove_remote("origin") if has_origin?(git)
          git.add_remote("origin", uri.to_s)
        rescue Git::Error => e
          Rails.logger.warn("Failed to reset remote origin: #{e.message}")
          # Don't re-raise - this is cleanup, not critical
        rescue StandardError => e
          Rails.logger.warn("Unexpected error resetting remote origin: #{e.message}")
          # Don't re-raise - this is cleanup, not critical
        end
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
          raise GitError, "Could not remove remote origin" unless remove_remote_safely(git, "origin")
        end

        # Add the remote with the correct URL
        begin
          git.add_remote("origin", remote_url)
          Rails.logger.debug { "Added remote origin: #{remote_url}" }
        rescue Git::Error => e
          raise GitError, "Failed to add remote origin: #{e.message}"
        end
      rescue StandardError => e
        Rails.logger.error("Error in ensure_remote_origin: #{e.message}")
        raise GitError, "Failed to configure remote origin #{remote_url}: #{e.message}"
      end

      def configure_pull_strategy(git)
        git.config("pull.rebase", "true")
      rescue StandardError => e
        Rails.logger.warn("Failed to configure pull strategy: #{e.message}")
      end

      def has_origin?(git)
        return false unless git.respond_to?(:remotes)

        git.remotes.any? { |remote| remote.name == "origin" }
      rescue StandardError => e
        Rails.logger.warn("Error checking for origin remote: #{e.message}")
        false
      end

      def get_remote_url(git, remote_name)
        remote = git.remote(remote_name)
        return nil unless remote

        remote.url
      rescue StandardError => e
        Rails.logger.warn("Error getting remote URL: #{e.message}")
        nil
      end

      def remove_remote_safely(git, remote_name)
        remote = git.remote(remote_name)
        return true unless remote

        remote.remove if remote.respond_to?(:remove)

        !has_origin?(git)
      rescue StandardError => e
        Rails.logger.warn("Failed to remove remote #{remote_name}: #{e.message}")
        false
      end
    end
  end
end
