# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class SerializerBase
      def initialize(model:, metadata: {}, locales: Decidim.available_locales)
        @model = model
        @metadata = metadata.with_indifferent_access
        @locales = locales
        # Hash: structure to hold all translations for the serialized object
        @translations = locales.to_h do |lang|
          [lang.to_s, {
            id => {
              "metadata" => {
                "name" => @metadata[:name][lang],
                "description" => @metadata[:description][lang]
              }
            }
          }]
        end
        # Hash: model-specific attributes
        @attributes = {}
        # Array: demo data to be included in demo.json
        @demo = []
        # Array: implement if necessary to include assets (e.g., images)
        @assets = []
      end

      attr_reader :model, :translations, :attributes, :demo, :assets, :metadata, :locales

      # A unique random identifier for the serialized object
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
      def data
        {
          id:,
          class: model.class.name,
          name: "#{id}.metadata.name",
          description: "#{id}.metadata.description",
          version: metadata[:version] || "0.0.1",
          attributes:
        }
      end

      def serialize
        {
          data:,
          demo:
        }
      end

      # copies the serialized data into a template folder unto the given path
      def save!(destination_path)
        path = File.join(destination_path, id)

        serialize.each do |key, content|
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

      def i18n_field(field)
        translations.deep_merge!(hash_to_i18n(field))

        "#{id}.attributes.#{field}"
      end

      def hash_to_i18n(field)
        hash = model.send(field)
        raise "Fields #{field} is not a Hash" unless hash.is_a?(Hash)

        locales.index_with do |lang|
          {
            id => {
              "attributes" => {
                field.to_s => hash[lang]
              }
            }
          }
        end
      end
    end
  end
end
