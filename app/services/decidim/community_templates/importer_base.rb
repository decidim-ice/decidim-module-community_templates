# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class ImporterBase
      def initialize(parser, organization, user, parent: nil)
        @parser = parser
        @organization = organization
        @user = user
        @parent = parent
      end

      attr_reader :parser, :organization, :user, :parent, :object

      def import!
        raise NotImplementedError, "You must implement the import! method in your importer"
      end

      def attach!(asset_id, field_name)
        asset_data = parser.assets.find { |asset| asset["id"] == asset_id }
        return nil unless asset_data

        Decidim::CommunityTemplates::Importers::Attachment.new(
          TemplateParser.new(
            data: { **asset_data, name: field_name },
            translations: parser.translations,
            locales: parser.locales,
            assets: parser.assets
          ),
          organization,
          user,
          parent: self
        ).import!
      end

      def locales
        organization.available_locales
      end

      def required!(field, value)
        valid = value && value.present?
        valid &&= !value.empty? if value.is_a?(Array) || value.is_a?(Hash)
        raise "Value for #{field} is required" unless valid

        value
      end

      def slugify(text)
        text = text.values.first if text.is_a?(Hash)
        base_slug = text.to_s.parameterize
        slug = base_slug
        count = 2
        while parser.model_class.unscoped.exists?(slug:, organization:)
          slug = "#{base_slug}-#{count}"
          count += 1
        end

        slug
      end
    end
  end
end
