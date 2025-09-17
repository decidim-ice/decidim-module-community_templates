# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class CatalogAdapter
      def initialize(options = {})
        @options = options
      end

      attr_reader :options

      def metadata
        raise NotImplementedError
      end

      def collection
        raise NotImplementedError
      end

      def import!(path)
        collection.each do |zip_file|
          Zip::File.open(zip_file) do |zip|
            zip.each do |entry|
              dest_file = File.join(path, entry.name)
              FileUtils.mkdir_p(File.dirname(dest_file))
              zip.extract(entry, dest_file) { true }
            end
          end
        end
      end

      def name
        metadata["name"]
      end

      def description
        metadata["description"]
      end

      def version
        metadata["version"]
      end
    end
  end
end
