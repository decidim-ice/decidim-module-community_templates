# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class SerializerBase
      def initialize(model)
        @model = model
      end

      # A unique random identifier for the serialized object
      def id
        SecureRandom.uuid
      end

      attr_reader :model

      def manifest
        raise NotImplementedError, "You must implement the manifest method"
      end

      def data
        raise NotImplementedError, "You must implement the data method"
      end

      def demo
        raise NotImplementedError, "You must implement the demo method"
      end

      # implement if necessary to include assets (e.g., images)
      def assets
        []
      end

      def json_files
        {
          manifest:,
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
      end
    end
  end
end
