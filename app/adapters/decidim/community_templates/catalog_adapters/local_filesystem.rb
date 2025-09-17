# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module CatalogAdapters
      class LocalFilesystem < Decidim::CommunityTemplates::CatalogAdapter
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

            # create a zip with all the contents of the directory
            basename = File.basename(dir)
            zipfile = Tempfile.new([basename, ".zip"])
            Zip::File.open(zipfile.path, Zip::File::CREATE) do |zip|
              Dir.glob("#{dir}/**/*").each do |file|
                next if File.directory?(file)

                # Create a zip entry for the file conserving the directory structure
                # inside the base directory
                # e.g. if dir is /path/to/catalog and file is /path/to/catalog/template1/template.json
                # the entry in the zip will be template1/template.json
                entry = file.sub("#{dir}/", "#{basename}/")
                zip.add(entry, file)
              end
            end
            zipfiles << zipfile
          end
          zipfiles
        end
      end
    end
  end
end
