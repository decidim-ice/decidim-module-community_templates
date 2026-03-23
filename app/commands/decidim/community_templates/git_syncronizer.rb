# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class GitSyncronizer < ::Decidim::Command
      LOCK_FILE_PATH = Rails.root.join("tmp/git_syncronizer.lock")

      def initialize(options = {})
        @git_mirror = options[:git_mirror] || GitMirror.instance
        @file_lock = options[:file_lock] || FileLock.new(LOCK_FILE_PATH)
        @cache = options[:cache] || SyncCache.new(Rails.cache, Decidim::CommunityTemplates.cache_namespace)
        @logger = options[:logger] || Rails.logger
        @public_files_reloader = options[:public_files_reloader]
        @invalid_models_cleaner = options[:invalid_models_cleaner]
        @apartment_strategy = options[:apartment_strategy]
        @job_class = options[:job_class] || Decidim::CommunityTemplates::ResetOrganizationJob
      end

      def call
        return unless CommunityTemplates.enabled?

        @file_lock.with_lock do |acquired|
          if acquired
            perform_sync
          else
            @logger.info "GitSyncronizer already running, skipping"
          end
        end
      end

      private

      def perform_sync
        result = GitCatalogNormalizer.call

        invalid_models_cleaner.call

        if result.has_key?(:invalid)
          @logger.error "Can not sync"
          return
        end

        @git_mirror.pull!
        last_commit = @git_mirror.last_commit

        if last_commit.present? && last_commit != @cache.last_commit
          public_files_reloader.call
          @job_class.perform_later
          @cache.update_last_commit(last_commit)
        end
      end

      def invalid_models_cleaner
        @invalid_models_cleaner ||= InvalidModelsCleaner.new(
          Decidim::CommunityTemplates.catalog_path,
          apartment_strategy: apartment_strategy
        )
      end

      def public_files_reloader
        @public_files_reloader ||= PublicFilesReloader.new(
          Decidim::CommunityTemplates.catalog_path,
          Rails.public_path.join("catalog")
        )
      end

      def apartment_strategy
        @apartment_strategy ||= ApartmentStrategy.for
      end
    end
  end
end
