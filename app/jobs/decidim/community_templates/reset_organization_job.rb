# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class ResetOrganizationJob < ApplicationJob
      def perform
        ResetOrganization.call
      end
    end
  end
end
