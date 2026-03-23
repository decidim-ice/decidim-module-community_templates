# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class PublicFilesReloader
      def initialize(catalog_path, public_path)
        @catalog_path = catalog_path
        @public_path = public_path
      end

      def call
        return unless @catalog_path.exist?

        swap_dir = "#{@public_path}.swp"
        FileUtils.rm_rf(swap_dir)
        FileUtils.mkdir_p(swap_dir)

        [
          @catalog_path,
          @catalog_path.join("shared")
        ].each do |path|
          next unless path.exist?

          template_dirs = path.children.select do |d|
            d.directory? && d.basename.to_s.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
          end
          template_dirs.each do |dir|
            FileUtils.cp_r(dir, swap_dir)
          end
        end

        FileUtils.rm_rf(@public_path)
        FileUtils.mv(swap_dir, @public_path)
      end
    end
  end
end
