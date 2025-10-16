# frozen_string_literal: true

require "git"
require "securerandom"
require "timeout"
module Decidim
  module CommunityTemplates
    class GitTransaction
      LOCKFILE = ".git/git-debate.lock"
      MAX_RETRIES = 3

      def initialize(git)
        @git = git
        @timeout = 60
        Git.config.timeout = @timeout
      end

      def self.perform(git, remote: "origin", push_opts: {}, timeout: nil, &)
        new(git).perform(remote: remote, push_opts: push_opts, timeout: timeout, &)
      end

      def perform(remote: "origin", push_opts: {}, timeout: nil)
        Rails.logger.info { "#perform [remote: #{remote}, push_opts: #{push_opts}, timeout: #{timeout}]" }

        effective_timeout = timeout || @timeout

        with_timeout(effective_timeout) do
          File.open(LOCKFILE, File::RDWR | File::CREAT, 0o644) do |f|
            f.flock(File::LOCK_EX)
            ensure_git_is_present!
            # Check if repository is dirty before proceeding
            raise Git::Error, "catalog dirty, commit or stash changes to continue" if dirty?

            assert_head_on!(default_branch)

            t_branch = "tx/#{Time.now.utc.strftime("%Y%m%d%H%M%S")}-#{SecureRandom.hex(4)}"

            safe_checkout(t_branch)

            begin
              yield @git # == Do the work on the topic branch ==
              # Try to merge with retries
              if writable?
                merge_with_retries(t_branch)
                raise "merge fails, still dirty" if dirty?

                # Try to push with retries (pull/rebase on failure)
                push_with_retries(remote, push_opts)
              else
                safe_checkout(default_branch)
                safe_delete_branch(t_branch)
              end
            rescue Git::Error => e
              Rails.logger.info { "#perform [error: #{e.message}]" }
              Rails.logger.info { "#perform [backtrace: #{e.backtrace.join("\n")}]" }
              # Rollback: ensure we end in a clean state on default branch
              safe_checkout(default_branch)
              safe_delete_branch(t_branch)
              raise e
            ensure
              # Ensure head is back on default even on non-Git exceptions
              safe_checkout(default_branch)
              raise "merge fails, still dirty" if dirty?
            end
          ensure
            f.flock(File::LOCK_UN)
          end
        end
      end

      private

      def ensure_git_is_present!
        pathname = Pathname.new(@git.dir.path)
        # Check the path is in a git working tree
        raise Git::Error, "Path is not in a git working tree" unless pathname.exist?
        raise Git::Error, "Path is not a git repository" unless pathname.join(".git").exist?
      end

      def writable?
        repo_url = @git.remote("origin").url
        return false if repo_url.blank?

        uri = URI.parse(repo_url)
        uri.user.present? && uri.password.present? && @git.index.writable?
      end

      def merge_with_retries(t_branch)
        Rails.logger.info { "#merge_with_retries [default_branch: #{default_branch}, t_branch: #{t_branch}]" }
        retries = 0
        begin
          safe_checkout(default_branch)
          @git.merge(t_branch, "merge #{t_branch}")
          @git.branch(t_branch).delete
        rescue Git::Error => e
          Rails.logger.info { "#merge_with_retries [error: #{e.message}]" }
          Rails.logger.info { "#merge_with_retries [backtrace: #{e.backtrace.join("\n")}]" }
          retries += 1
          raise e unless retries <= MAX_RETRIES

          # Reset to clean state and try again
          @git.reset_hard(default_branch)
          safe_checkout(t_branch)
          sleep(0.1 * retries) # Brief delay before retry
          retry
        end
      end

      def push_with_retries(remote, push_opts)
        Rails.logger.info { "#push_with_retries [remote: #{remote}, default_branch: #{default_branch}, push_opts: #{push_opts}]" }
        retries = 0
        begin
          @git.push(remote, default_branch, **push_opts)
        rescue Git::Error => e
          Rails.logger.info { "#push_with_retries [error: #{e.message}]" }
          Rails.logger.info { "#push_with_retries [backtrace: #{e.backtrace.join("\n")}]" }
          retries += 1
          raise e unless retries <= MAX_RETRIES

          # Pull latest changes and rebase
          @git.pull(remote, default_branch)
          @git.rebase(default_branch)
          sleep(0.1 * retries) # Brief delay before retry
          retry
        end
      end

      def with_timeout(seconds, &blk)
        Rails.logger.info { "#with_timeout [seconds: #{seconds}]" }
        return blk.call if seconds.nil? || seconds.to_f <= 0

        Timeout.timeout(seconds, Git::Error) { blk.call }
      end

      def default_branch
        @default_branch ||= begin
          branch = Decidim::CommunityTemplates.git_settings[:branch]
          prev_branch = @git.current_branch
          safe_checkout(branch)
          safe_checkout(prev_branch)
          branch
        end
      end

      def assert_head_on!(branch)
        Rails.logger.info { "#assert_head_on! [branch: #{branch}]" }
        cur = @git.current_branch
        raise Git::Error, "HEAD not on #{branch.inspect} (at #{cur.inspect})" unless cur == branch
      end

      def safe_checkout(branch)
        Rails.logger.info { "#safe_checkout [branch: #{branch}]" }
        @git.checkout(branch)
      rescue Git::Error => e
        Rails.logger.info { "#safe_checkout [error: #{e.message}]" }
        Rails.logger.info { "#safe_checkout [backtrace: #{e.backtrace.join("\n")}]" }
        raise e if branch.nil? || branch.blank?

        if @git.branches.local.any? { |b| b.name == branch }
          @git.reset_hard(branch)
          @git.checkout(branch)
        else
          @git.checkout(branch, new_branch: true)
        end
      end

      def safe_delete_branch(name)
        Rails.logger.info { "#safe_delete_branch [name: #{name}]" }
        @git.branch(name).delete if @git.local_branch?(name)
      rescue Git::Error => e
        Rails.logger.info { "#safe_delete_branch [error: #{e.message}]" }
        Rails.logger.info { "#safe_delete_branch [backtrace: #{e.backtrace.join("\n")}]" }
        # ignore
      end

      def dirty?
        status = @git.status
        status.changed.any? || status.added.any? || status.deleted.any? || status.untracked.any?
      rescue Git::Error => e
        Rails.logger.info { "#dirty? [error: #{e.message}]" }
        # If we can't check status, assume it's dirty to be safe
        true
      end
    end
  end
end
