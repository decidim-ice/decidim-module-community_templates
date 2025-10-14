# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class TemplateParser
      def initialize(data:, assets:, translations: {}, locales: Decidim.available_locales.map(&:to_s), i18n_vars: {})
        raise ArgumentError, "Invalid parameter assets. Must be an array" if assets.nil? || !assets.is_a?(Array)

        @data = data
        @translations = translations
        @locales = locales
        @assets = assets
        @i18n_vars = i18n_vars
        store_translations!
      end

      attr_reader :data, :translations, :locales, :assets, :i18n_vars

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
          created_at: metadata["created_at"],
          default_locale: metadata["default_locale"]
        }
      end

      def default_locale
        metadata["default_locale"]
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
          unless has_value
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
        default_translation = I18n.t(field, locale: default_locale, **i18n_vars)
        locales.index_with do |locale|
          I18n.with_locale(locale) do
            I18n.t(field, default: default_translation, **i18n_vars)
          end
        end
      end

      def translation_for(field)
        return field unless field && field.is_a?(String)

        find_translation(field) || field
      end

      def populate_i18n_vars!(organization)
        # One per Decidim::EditorImage
        @i18n_vars = assets.select { |asset| asset && asset.dig("attributes", "record_type") == "Decidim::EditorImage" }.to_h do |asset|
          key = asset["id"].to_s.parameterize.underscore
          editor_image = Decidim::EditorImage.create!(
            author: default_author(organization),
            organization: organization
          )
          blob = ActiveStorage::Blob.create_and_upload!(
            io: File.open(asset["attributes"]["@local_path"]),
            filename: (asset["attributes"]["filename"]).to_s,
            content_type: asset["attributes"]["content_type"],
            identify: false
          )
          editor_image.file.save if editor_image.file.attach(blob)
          [key.to_sym, Rails.application.routes.url_helpers.rails_blob_url(editor_image.file.blob, only_path: true)]
        end
      end

      private

      def find_translation(field)
        default_translation = I18n.t(field, locale: default_locale, default: nil, **i18n_vars)
        return field if default_translation.blank?

        I18n.t(field, default: default_translation, locale: I18n.locale, **i18n_vars)
      end

      def store_translations!
        locales.each do |locale|
          I18n.backend.store_translations(locale, translations[locale] || {})
        end
      end

      def default_author(organization)
        Decidim::User.find_by(admin: true, organization:)
      end
    end
  end
end
