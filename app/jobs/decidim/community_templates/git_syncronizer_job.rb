# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class GitSyncronizerJob < ApplicationJob
      queue_as :default
      discard_on Decidim::CommunityTemplates::GitError
      retry_on Git::Error, wait: 1.minute, attempts: 3

      def perform
        return unless CommunityTemplates.enabled?

        # Be sure to apply configuration to current git
        GitCatalogNormalizer.call

        git_mirror = GitMirror.instance
        git_mirror.validate!

        git_mirror.push! if git_mirror.writable?

        git_mirror.pull

        reload_public_files!
      end

      private

      def reload_public_files!
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
