# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class GitSyncronizerJob < ApplicationJob
      def perform
        GitSyncronizer.call
      end
    end
  end
end
