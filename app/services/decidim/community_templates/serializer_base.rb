# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class SerializerBase
      def initialize(model:, metadata: {}, locales: Decidim.available_locales, with_manifest: false)
        @model = model
        @metadata = metadata.with_indifferent_access
        @locales = locales
        @with_manifest = with_manifest
        # Hash: structure to hold all translations for the serialized object
        @translations = {}
        # Hash: structure to hold the final serialized data
        @data = {}
        # Hash: model-specific attributes
        @attributes = {}
        # Array: implement if necessary to include demo data
        @demo = []
        # Array: implement if necessary to include assets (e.g., images)
        @assets = []
      end

      attr_reader :model, :translations, :attributes, :assets, :metadata, :locales, :with_manifest, :data, :demo

      def self.init(**args)
        serializer = new(**args)
        serializer.data!
        serializer.demo!
        serializer.assets!
        serializer
      end

      # For the moment, name and description are the only translatable metadata fields
      def metadata_translations!
        %w(name description).each do |field|
          translations.deep_merge!(hash_to_i18n(metadata[field], field, "metadata"))
        end
        translations
      end

      # A unique identifier for the serialized object
      def id
        return metadata[:id] if metadata[:id].present?

        @id ||= begin
          alternatives = []
          alternatives << model.slug if model.respond_to?(:slug)
          alternatives << model.manifest_name if model.respond_to?(:manifest_name)
          alternatives << model.manifest.name if model.respond_to?(:manifest)
          alternatives << model.created_at.strftime("%Y%m%d%H%M%S") if model.respond_to?(:created_at)

          alternatives.find(&:present?)
        end
      end

      # metadata for the serialized object, extend in subclasses using super
      # Other possible future fields here could define rules for generating the final object
      # (e.g. how to generate the slug, or publication status)
      def data!
        data[:id] = id
        data[:@class] = model.class.name
        data[:attributes] = attributes
        return unless with_manifest

        data[:name] = "#{id}.metadata.name" if metadata[:name].present?
        data[:description] = "#{id}.metadata.description" if metadata[:description].present?
        data[:version] = metadata[:version]
        data.merge!(metadata.except(:name, :description, :version))
        data[:decidim_version] = Decidim.version
        data[:community_templates_version] = Decidim::CommunityTemplates::VERSION
      end

      def demo!
        # TODO
      end

      def assets!
        # TODO
      end

      def json_files
        {
          data:,
          demo:
        }
      end

      # copies the serialized data into a template folder unto the given path
      def save!(destination_path)
        path = File.join(destination_path, id)

        json_files.each do |key, content|
          FileUtils.mkdir_p(path)
          file_path = File.join(path, "#{key}.json")
          File.write(file_path, JSON.pretty_generate(content))
        end

        assets.each do |asset_path|
          next unless File.exist?(asset_path)

          dest_path = File.join(path, "assets", File.basename(asset_path))
          FileUtils.mkdir_p(File.dirname(dest_path))
          FileUtils.cp(asset_path, dest_path)
        end

        translations.each do |lang, texts|
          lang_path = File.join(path, "locales")
          FileUtils.mkdir_p(lang_path)
          file_path = File.join(lang_path, "#{lang}.yml")
          File.write(file_path, { lang => texts }.to_yaml)
        end
      end

      private

      def id_parts
        id.split(".")
      end

      def i18n_field(field)
        value = model.send(field)
        unless value.is_a?(Hash)
          value = {
            locales.first => value
          }
        end

        translations.deep_merge!(hash_to_i18n(value, field))

        "#{id}.attributes.#{field}"
      end

      def hash_to_i18n(hash, field, prefix = "attributes")
        hash = { locales.first => hash } unless hash.is_a?(Hash)

        locales.index_with do |lang|
          (id_parts + [prefix, field.to_s]).reverse.inject(hash[lang]) { |value, key| { key => value } }
        end
      end

      def append_serializer(serializer_class, model, prefix)
        serializer = serializer_class.init(model:, metadata: { id: "#{id}.attributes.#{prefix}" }, locales:)
        translations.deep_merge!(serializer.translations)
        serializer.data
      end
    end
  end
end
