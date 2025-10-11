# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class TemplateParser
      def initialize(data:, assets:, translations: {}, locales: Decidim.available_locales.map(&:to_s))
        raise ArgumentError, "Invalid parameter assets. Must be an array" if assets.nil? || !assets.is_a?(Array)

        @data = data
        @translations = translations
        @locales = locales
        @assets = assets
      end

      attr_reader :data, :translations, :locales, :assets

      delegate :id, :name, :description, :version, :author, :links, :source_type, to: :template

      def model_class
        return nil unless model_class?

        @model_class ||= metadata["@class"].constantize
      end

      def model_class?
        return false if metadata.blank?

        metadata["@class"].present? && Object.const_defined?(metadata["@class"])
      rescue NameError
        false
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
        method_name = method.to_s
        if method_name.start_with?("model_")
          key = method_name.sub("model_", "")
          available_attributes = model_class.new.attributes.keys
          is_available = available_attributes.include?(key)
          has_value = attributes.has_key?(key)
          unless is_available && has_value
            # Attribute name exists, but has no value
            return nil if is_available

            # Attribute name does not exist, give a suggestion
            dictionary = available_attributes.map { |attribute| "model_#{attribute}" }
            suggestions = DidYouMean::SpellChecker.new(dictionary: dictionary).correct(method_name)
            raise NoMethodError, "Undefined method `#{method_name}` for #{self.class}. Did you mean #{suggestions.join(", ")}?"
          end

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
        return field unless field && field.is_a?(String)

        find_translation(field) || field
      end

      private

      def find_translation(field)
        locales.each do |locale|
          value = translations.dig(locale.to_s, *field.split("."))
          return value if value && value.to_s.present?
        end
        nil
      end
    end
  end
end
