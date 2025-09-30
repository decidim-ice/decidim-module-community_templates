# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class DirectLinkImporter
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def form
        Decidim::CommunityTemplates::Admin::DirectLinkForm.from_params(params)
      end
    end
  end
end
