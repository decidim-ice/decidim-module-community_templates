# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class GitSyncronizerJob < ApplicationJob
      queue_as :default
      discard_on Decidim::CommunityTemplates::GitError
      retry_on Git::Error, wait: 1.minute, attempts: 3
      def perform
        return if CommunityTemplates.git_settings[:url].blank?

        # Be sure to apply configuration to current git
        GitCatalogNormalizer.call

        git_mirror = GitMirror.instance
        git_mirror.validate!

        if git_mirror.git.status.untracked.size.positive?
          git_mirror.git.add(all: true)
          # Commit changes
          git_mirror.git.commit(message: "Update community templates")
          git_mirror.push!
        end
        git_mirror.pull
      end
    end
  end
end
