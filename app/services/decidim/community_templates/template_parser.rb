# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class TemplateParser
      I18N_PATTERN = /^[a-z0-9_-]+\.([a-z0-9_-]+\.)*([a-z0-9_-])*$/
      def initialize(data:, assets:, translations: {}, locales: Decidim.available_locales.map(&:to_s), **options)
        raise ArgumentError, "Invalid parameter assets. Must be an array" if assets.nil? || !assets.is_a?(Array)

        @data = data
        @translations = translations
        @locales = locales
        @assets = assets
        @i18n_vars = options[:i18n_vars] || {}
        @relations = options[:relations] || {}
        store_translations!
        add_methods!
      end

      attr_reader :data, :translations, :locales, :assets, :i18n_vars, :relations

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

      def respond_to_missing?(method, include_private = false)
        if method.to_s.start_with?("model_")
          key = method.to_s.sub("model_", "")
          return true if attributes.has_key?(key)
        end
        super
      end

      def all_translations_for(field, locales, ignore_missing: false)
        on_missing = ignore_missing ? "" : "Translation missing: #{field}"
        default_translation = I18n.t(field, locale: default_locale, default: on_missing, **i18n_vars)
        locales.index_with do |locale|
          I18n.with_locale(locale) do
            I18n.t(field, default: default_translation, **i18n_vars)
          end
        end
      end

      def translation_for(field, ignore_missing: false)
        return field unless !ignore_missing && field && field.is_a?(String)

        find_translation(field, ignore_missing: ignore_missing) || field
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

      def find_translation(field, ignore_missing: false)
        on_missing = ignore_missing ? "" : "Translation missing: #{field}"
        default_translation = I18n.t(field, locale: default_locale, default: on_missing, **i18n_vars)
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

      def add_methods!
        return unless model_class?

        (attributes.keys + model_class.new.attributes.keys).uniq.each do |attribute|
          # model_title(locales, ignore_missing: true)
          singleton_class.define_method("model_#{attribute}") do |*args, **kwargs|
            locales = args.first if args.first.is_a?(Array)
            value = attributes[attribute]
            if !value.is_a?(String) || !value.match?(I18N_PATTERN)
              value
            elsif locales && locales.size.positive?
              all_translations_for(attributes[attribute], locales, **kwargs)
            else
              translation_for(attributes[attribute], **kwargs)
            end
          end
        end
      end
    end
  end
end
