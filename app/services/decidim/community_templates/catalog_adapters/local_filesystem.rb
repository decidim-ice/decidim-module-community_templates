# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module CatalogAdapters
      class LocalFilesystem < Decidim::CommunityTemplates::CatalogAdapterBase
        def base_path
          options[:path]
        end

        def manifest_file
          @manifest_file ||= File.join(base_path, "manifest.json")
        end

        def metadata
          return unless File.exist?(manifest_file)

          JSON.parse(File.read(manifest_file))
        end

        # collection of zip files, one per catalog found in the base path
        def collection
          zipfiles = []
          Dir.glob("#{base_path}/*").each do |dir|
            next unless File.directory?(dir)

            package = Zipper.create_from(dir)
            zipfiles << package.zipfile if package
          end
          zipfiles
        end
      end
    end
  end
end
