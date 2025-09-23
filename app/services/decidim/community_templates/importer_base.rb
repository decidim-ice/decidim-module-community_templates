# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class ImporterBase
      def initialize(parser, organization, user, demo: false)
        @parser = parser
        @organization = organization
        @user = user
        @demo = demo
      end

      attr_reader :parser, :organization, :user, :demo

      def import!
        raise NotImplementedError, "You must implement the import! method in your importer"
      end

      def locales
        organization.available_locales
      end

      def slugify(text)
        base_slug = text.to_s.parameterize
        slug = base_slug
        count = 2

        while parser.model_class.exists?(slug:, organization:)
          slug = "#{base_slug}-#{count}"
          count += 1
        end

        slug
      end
    end
  end
end
