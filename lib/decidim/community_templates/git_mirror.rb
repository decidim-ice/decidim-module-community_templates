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
          git.push("origin", repo_branch, force: true)
        end
      end

      def pull
        validate!

        git.pull("origin", repo_branch)
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
        @catalog_path = Rails.public_path.join("catalog")
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
        return errors.add(:base, "Repository is empty") if empty?
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

      def with_git_credentials
        ENV["GIT_USERNAME"] = repo_username
        ENV["GIT_PASSWORD"] = repo_password
        yield(git)
      ensure
        ENV["GIT_USERNAME"] = nil
        ENV["GIT_PASSWORD"] = nil
      end
    end
  end
end
