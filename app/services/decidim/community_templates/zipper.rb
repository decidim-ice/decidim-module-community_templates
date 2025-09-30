# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class Zipper
      def initialize(path:)
        @path = path
        @basename = File.basename(path)
      end

      attr_reader :path, :basename
      attr_accessor :zipfile

      def self.create_from(path)
        new(path: path).tap(&:zip!)
      end

      def self.extract_to(zip_file, path)
        Zip::File.open(zip_file) do |zip|
          zip.each do |entry|
            dest_file = File.join(path, entry.name)
            FileUtils.mkdir_p(File.dirname(dest_file))
            zip.extract(entry, dest_file) { true }
          end
        end
      end

      def zip!
        # create a zip with all the contents of the directory
        self.zipfile = Tempfile.new([basename, ".zip"])
        Zip::File.open(zipfile.path, Zip::File::CREATE) do |zip|
          Dir.glob("#{path}/**/*").each do |file|
            next if File.directory?(file)

            # Create a zip entry for the file conserving the directory structure
            # inside the base directory
            # e.g. if dir is /path/to/catalog and file is /path/to/catalog/template1/data.json
            # the entry in the zip will be template1/data.json
            entry = Pathname.new(file).relative_path_from(Pathname.new(path).parent).to_s
            zip.add(entry, file)
          end
        end
      end
    end
  end
end
