# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class SyncCache
      CACHE_KEY = "git_syncronizer_last_commit"

      def initialize(cache_store, namespace)
        @cache_store = cache_store
        @namespace = namespace
      end

      def last_commit
        @cache_store.read(CACHE_KEY, namespace: @namespace)
      end

      def update_last_commit(commit_sha)
        @cache_store.write(CACHE_KEY, commit_sha, namespace: @namespace)
      end
    end
  end
end

