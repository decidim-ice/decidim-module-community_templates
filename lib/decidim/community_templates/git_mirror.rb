# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class GitMirror
      include Singleton

      attr_reader :repo_url, :repo_branch, :repo_username, :repo_password, :repo_author_name, :repo_author_email, :errors
      attr_accessor :catalog_path

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
        return false unless repo_username && repo_password && !repo_username.blank? && !repo_password.blank?

        with_git_credentials do |git|
          git.index.writable?
        end
      end

      def initialize
        @errors = ActiveModel::Errors.new(self)
        @catalog_path = Rails.public_path.join("catalog")
      end

      def configure(options)
        @repo_url = options[:repo_url]
        @repo_branch = options[:repo_branch]
        @repo_username = options[:repo_username]
        @repo_password = options[:repo_password] || ""
        @repo_author_name = options[:repo_author_name]
        @repo_author_email = options[:repo_author_email]
        self
      end

      def valid?
        validate
        errors.empty?
      end

      def validate!
        validate
        raise errors.full_messages.join(", ") unless errors.empty?
      end

      def validate
        errors.clear
        # Validate configuration
        validate_repository_url
        validate_repository_password
        validate_repository_username
        validate_repository_author_name
        validate_repository_author_email

        # Validate catalog paths and normalization
        return errors.add(:base, "Repository catalog path does not exist. Check #{catalog_path}.") unless catalog_path.exist?
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
      end

      private

      def validate_repository_url
        return errors.add(:base, "Repository URL is not set") unless repo_url
        return errors.add(:base, "Repository URL is not a valid https url") unless repo_url.match?(%r{\Ahttps://})
      end

      def validate_repository_password
        return if repo_username.nil? || repo_username.blank?
        return errors.add(:base, "Repository password is not set") if repo_password.blank?
      end

      def validate_repository_username
        return if repo_password.nil? || repo_password.blank?
        return errors.add(:base, "Repository username is not set") if repo_username.blank?
      end

      def validate_repository_author_name
        return errors.add(:base, "Repository author name is not set") unless repo_author_name
        return errors.add(:base, "Repository author name is not at least 3 characters") unless repo_author_name.length >= 3
      end

      def validate_repository_author_email
        return errors.add(:base, "Repository author email is not set") unless repo_author_email
        return errors.add(:base, "Repository author email is not a valid email") unless repo_author_email.match?(URI::MailTo::EMAIL_REGEXP)
      end

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
