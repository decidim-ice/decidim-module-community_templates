# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class SerializerBase
      def initialize(model)
        @model = model
        @translations = {}
      end

      attr_reader :model, :translations

      # A unique random identifier for the serialized object
      def id
        @id ||= [
          Time.now.to_i.to_s(36)[-4..].rjust(4, "0"),
          Time.now.usec.to_s(36)[-4..].rjust(4, "0"),
          rand(36**4).to_s(36).rjust(4, "0"),
          rand(36**4).to_s(36).rjust(4, "0")
        ].join("-")
      end

      # only common model fields, extend in subclasses using super
      def data
        {
          id:,
          class: model.class.name
        }
      end

      def demo
        []
      end

      # implement if necessary to include assets (e.g., images)
      def assets
        []
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
      end

      private

      def i18n_field(field)
        translations.deep_merge!(hash_to_i18n_yaml(field))

        "#{id}.#{field}"
      end

      def hash_to_i18n_yaml(field)
        hash = model.send(field)
        raise "Fields #{field} is not a Hash" unless hash.is_a?(Hash)

        hash.filter_map do |lang, text|
          next if text.to_s.strip.blank?
          next if text.is_a?(Hash)

          [lang, {
            id => {
              field.to_s => text
            }
          }]
        end.to_h
      end
    end
  end
end
