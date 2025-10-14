# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class GitSyncronizer < ::Decidim::Command
      def call
        return unless CommunityTemplates.enabled?

        # Be sure to apply configuration to current git
        result = GitCatalogNormalizer.call

        if result.has_key?(:invalid)
          Rails.logger.error "Can not sync"
          return
        end

        git_mirror = GitMirror.instance
        git_mirror.validate!
        git_mirror.push! if git_mirror.writable?
        git_mirror.pull
        # cache from last commit
        last_commit = git_mirror.last_commit
        if last_commit.present? && last_commit != Rails.cache.read("git_syncronizer_last_commit")
          reload_public_files!
          Decidim::CommunityTemplates::ResetOrganization.call
          Rails.cache.write("git_syncronizer_last_commit", last_commit)
        end
      end

      private

      def reload_public_files!
        return unless Decidim::CommunityTemplates.catalog_path.exist?

        # Create a public/catalog.swp the time to copy files, and then replace the original
        public_catalog_path = Rails.public_path.join("catalog")
        swap_dir = "#{public_catalog_path}.swp"
        FileUtils.rm_rf(swap_dir)
        FileUtils.mkdir_p(swap_dir)
        # Go over every directory that matches uuid and copy it to the swap directory
        Dir.glob(Decidim::CommunityTemplates.catalog_path.children.select do |d|
          d.directory? && d.basename.to_s.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
        end).each do |dir|
          FileUtils.cp_r(dir, swap_dir)
        end

        # Replace the original catalog with the swap directory
        FileUtils.rm_rf(public_catalog_path)
        FileUtils.mv(swap_dir, public_catalog_path)
      end
    end
  end
end
