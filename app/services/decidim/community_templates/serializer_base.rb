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
        serializer.metadata_translations!
        serializer.data!
        serializer.demo!
        serializer.assets!
        serializer
      end

      # For the moment, name and description are the only translatable metadata fields
      def metadata_translations!
        %w(name description).each do |field|
          next unless metadata[field].is_a?(Hash)

          translations.deep_merge!(hash_to_i18n(metadata[field], field, "metadata"))
        end
        translations
      end

      # A unique random identifier with very low collision probability for the serialized object
      def id
        return metadata[:id] if metadata[:id].present?

        @id ||= [
          Time.now.to_i.to_s(36)[-4..].rjust(4, "0"),
          Time.zone.now.usec.to_s(36)[-4..].rjust(4, "0"),
          rand(36**4).to_s(36).rjust(4, "0"),
          rand(36**4).to_s(36).rjust(4, "0")
        ].join("-")
      end

      # metadata for the serialized object, extend in subclasses using super
      # Other possible future fields here could define rules for generating the final object
      # (e.g. how to generate the slug, or publication status)
      def data!
        data[:id] = id
        data[:class] = model.class.name
        data[:original_id] = model.id
        data[:attributes] = attributes
        if with_manifest
          data[:name] = "#{id}.metadata.name" if metadata[:name].present?
          data[:description] = "#{id}.metadata.description" if metadata[:description].present?
          data[:decidim_version] = Decidim.version
          data[:community_templates_version] = Decidim::CommunityTemplates::VERSION
          data[:version] = metadata[:version] || "0.0.1"
        end
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
        translations.deep_merge!(hash_to_i18n(model.send(field), field))

        "#{id}.attributes.#{field}"
      end

      def hash_to_i18n(hash, field, prefix = "attributes")
        return {} unless hash.is_a?(Hash)

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
