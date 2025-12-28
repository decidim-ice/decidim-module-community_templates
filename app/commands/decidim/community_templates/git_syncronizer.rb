# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class GitSyncronizer < ::Decidim::Command
      LOCK_FILE_PATH = Rails.root.join("tmp/git_syncronizer.lock")

      def initialize(
        git_mirror: nil,
        file_lock: nil,
        cache: nil,
        logger: nil,
        public_files_reloader: nil,
        invalid_models_cleaner: nil,
        apartment_strategy: nil,
        job_class: nil
      )
        @git_mirror = git_mirror || GitMirror.instance
        @file_lock = file_lock || FileLock.new(LOCK_FILE_PATH)
        @cache = cache || SyncCache.new(Rails.cache, Decidim::CommunityTemplates.cache_namespace)
        @logger = logger || Rails.logger
        @public_files_reloader = public_files_reloader
        @invalid_models_cleaner = invalid_models_cleaner
        @apartment_strategy = apartment_strategy
        @job_class = job_class || Decidim::CommunityTemplates::ResetOrganizationJob
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
