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
          Zipper.extract_to(zip_file, path)
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
