# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class Error < StandardError
    end

    class GitError < Error
    end

    class ResetOrganizationError < Error
    end
  end
end
