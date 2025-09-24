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
        git_mirror.push!

        git_mirror.pull
      end
    end
  end
end
