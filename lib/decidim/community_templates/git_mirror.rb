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
          if git.status.untracked.size.positive? || git.status.changed.size.positive?
            git.add(all: true)
            git.commit_all("Update community templates")
          end
          next unless git.status.any?

          git.push("origin", repo_branch.to_s, force: true)
        end
      end

      def pull
        # If we are synced with a remote git repository, we need to push first.
        return if !git.status.changed.empty? && writable?

        validate!
        with_git_credentials do |git|
          git.remote("origin").fetch
          checkout_branch(git, repo_branch)
          git.push("origin", repo_branch) if writable? && (!remote_branch_exists?(git) || !git.status.changed.empty?)
          git.pull
        end
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

      def with_git_credentials
        # Parse URI and add username and password
        uri = URI.parse(repo_url)
        uri.user = repo_username
        uri.password = repo_password
        git.remove_remote("origin") if has_origin?(git)
        git.add_remote("origin", uri.to_s)
        yield(git)
      ensure
        git.remove_remote("origin") if has_origin?(git)
      end

      def has_origin?(git)
        git.remotes.any? { |remote| remote.name == "origin" }
      end

      def remote_branch_exists?(git)
        git.branches.remote.any? { |branch| branch.name == "origin/#{repo_branch}" }
      rescue StandardError
        false
      end
    end
  end
end
