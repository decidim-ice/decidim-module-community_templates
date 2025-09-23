# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ParticipatoryProcess < ImporterBase
        def import!
          Decidim::ParticipatoryProcess.create!(
            organization:,
            title: parser.model_title(locales),
            slug: slugify(parser.model_title),
            subtitle: parser.model_subtitle(locales),
            short_description: parser.model_short_description(locales),
            description: parser.model_description(locales)
          )
        end
      end
    end
  end
end
