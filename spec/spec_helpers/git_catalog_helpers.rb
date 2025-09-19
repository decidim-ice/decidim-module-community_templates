# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module SpecHelpers
      module GitCatalogHelpers
        def initialize_ready_catalog(path)
          FileUtils.mkdir_p(path)
          File.write(path.join("manifest.json"), "{}")
          git = Git.open(path)
          git.add(path.join("manifest.json"))
          git.commit(":tada:")
        end
      end
    end
  end
end
