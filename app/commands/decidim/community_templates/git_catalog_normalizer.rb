# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    ##
    # Normalize the Git repository specified in the GitMirror.
    # - clone the repository if it doesn't exist
    # - check the remote url is correct
    # - check there is at least one commit
    # - add an empty manifest.json file if there is no commit
    # - push the changes to the repository
    #
    # This job should be run after git mirror configuration upgrade, and
    # before a mirroring.
    class GitCatalogNormalizer < ::Decidim::Command
      delegate :repo_url, :repo_branch, :repo_author_name, :repo_author_email, :catalog_path, :templates_count, :empty?, to: :git_mirror
      attr_reader :git_mirror

      def initialize
        @git_mirror = GitMirror.instance
      end

      def call
        return broadcast(:ok) unless Decidim::CommunityTemplates.enabled?
        return broadcast(:invalid, "Internal: GitMirror is not configured") unless git_mirror.configured?

        unless git_working_tree?
          # destroy folder to clone again
          Rails.logger.info { "Catalog is not a git working tree, re-creating folder #{catalog_path}" }
          FileUtils.rm_rf(catalog_path)
        end
        clone_repository unless catalog_path.exist?
        validate!
        configure_git
        checkout_branch
        tada_commit if empty?(git) || templates_count.zero?

        # Check there is at least one commit
        broadcast(:ok)
      rescue StandardError => e
        broadcast(:invalid, e.message)
      end

      private

      def git_working_tree?
        git_dir = @git_mirror.catalog_path
        git_dir.exist? && git_dir.join(".git").exist? && git.index.readable?
      rescue Git::Error
        false
      end

      def git
        @git ||= @git_mirror.open_git
      end

      ##
      # Checkout (or create) the branch specified in the git mirror.
      def checkout_branch
        git.checkout(repo_branch, new_branch: git.branches.local.none? { |branch| branch.name == repo_branch })
      rescue Git::FailedError => e
        Rails.logger.error("Error checking out branch #{repo_branch} from #{git.current_branch}: #{e.message}")
        raise e
      end

      ##
      # Ensure there is at least one commit in the repository.
      # We use this to setup a standard repository.
      def tada_commit
        @git_mirror.transaction do |g|
          tada_commit_fixture = Engine.root.join("lib", "decidim", "community_templates", "tada_commit")
          tada_commit_fixture.children.select { |child| child.extname == ".md" }.each do |file|
            file_path = catalog_path.join(file.basename).to_s
            File.write(file_path, file.read)
            g.add(file_path)
          end
          g.commit(":tada: Add empty manifest.json")
        end
      end

      ##
      # Setup git configuration.
      def configure_git
        git.config("remote.origin.branch", repo_branch) if repo_branch.present?
        git.config("user.name", repo_author_name)
        git.config("user.email", repo_author_email)
      end

      ##
      # Check previous git configuration is coherent with configured values.
      def validate!
        current_remote_url = safe_remote_url
        return if current_remote_url.nil? || current_remote_url.blank?
        raise "Repository URL mismatch: #{current_remote_url} != #{repo_url}. Delete catalog directory #{catalog_path} and run again." if current_remote_url != repo_url
      end

      def safe_remote_url
        return @safe_remote_url if @safe_remote_url.present?

        remote = git.remote("origin")
        return nil unless remote

        url = remote.url
        return nil if url.blank?

        @safe_remote_url ||= begin
          uri = URI.parse(url)
          uri.user = nil
          uri.password = nil
          uri.to_s
        rescue Git::Error
          nil
        end
      end

      ##
      # Clone the repository at catalog_path.
      def clone_repository
        Git.clone(repo_url, catalog_path.to_s)
      rescue Git::Error => e
        Rails.logger.error("Error cloning repository: #{e.message}")
        raise e
      end
    end
  end
end
