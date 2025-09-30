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

      def id
        @id ||= metadata["id"]
      end

      def model_class
        @model_class ||= metadata["class"].constantize
      end

      def name
        translation_for(metadata["name"])
      end

      def description
        translation_for(metadata["description"])
      end

      def version
        metadata["version"]
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
          translations.dig(locale, *field.to_s.split(".")) || ""
        end
      end

      def translation_for(field)
        return unless field && field.is_a?(String)

        find_translation(field) || field
      end

      private

      def find_translation(field)
        locales.each do |locale|
          value = translations.dig(locale, *field.split("."))
          return value if value
        end
        nil
      end
    end
  end
end
