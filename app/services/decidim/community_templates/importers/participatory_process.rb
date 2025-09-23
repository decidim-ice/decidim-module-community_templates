# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ParticipatoryProcess < ImporterBase
        def import!
          Decidim::ParticipatoryProcess.create!(
            organization:,
            title: parser.model_title(locales),
            slug: slugify(parser.model_title)
          )
        end
      end
    end
  end
end
