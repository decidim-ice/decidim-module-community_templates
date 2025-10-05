# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class TemplateParser
      def initialize(data:, translations: {}, locales: Decidim.available_locales.map(&:to_s))
        @data = data
        @translations = translations
        @locales = locales
      end

      attr_reader :data, :translations, :locales

      delegate :id, :name, :description, :version, :author, :links, :source_type, to: :template

      def model_class
        return nil if metadata.blank?

        @model_class ||= metadata["@class"].constantize
      end

      def template
        @template ||= TemplateMetadata.new(template_attributes)
      end

      def template_attributes
        @template_attributes ||= {
          id: metadata["id"],
          name: translation_for(metadata["name"]),
          description: translation_for(metadata["description"]),
          version: metadata["version"],
          author: metadata["author"],
          links: metadata["links"],
          "@class": metadata["@class"],
          community_templates_version: metadata["community_templates_version"],
          decidim_version: metadata["decidim_version"],
          archived_at: metadata["archived_at"],
          updated_at: metadata["updated_at"],
          created_at: metadata["created_at"]
        }
      end

      def metadata
        data.except("attributes")
      end

      def attributes
        data["attributes"] || {}
      end

      # if an array of locales is given, it will return a hash with the translations
      # otherwise it will return the translation in the first locale available
      def method_missing(method, *args, &)
        if method.to_s.start_with?("model_")
          key = method.to_s.sub("model_", "")
          return nil unless attributes.has_key?(key)

          value = attributes[key]
          # If an array of locales is given as argument, return a hash with translations
          return translation_for(value) unless args.first.is_a?(Array)

          return all_translations_for(value, args.first)
        end
        super
      end

      def respond_to_missing?(method, include_private = false)
        if method.to_s.start_with?("model_")
          key = method.to_s.sub("model_", "")
          return true if attributes.has_key?(key)
        end
        super
      end

      def all_translations_for(field, locales)
        locales.index_with do |locale|
          translations.dig(locale.to_s, *field.to_s.split(".")) || ""
        end
      end

      def translation_for(field)
        return unless field && field.is_a?(String)

        find_translation(field) || field
      end

      private

      def find_translation(field)
        locales.each do |locale|
          value = translations.dig(locale.to_s, *field.split("."))
          return value if value
        end
        nil
      end
    end
  end
end
