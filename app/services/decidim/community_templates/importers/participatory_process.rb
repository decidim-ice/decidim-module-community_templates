# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ParticipatoryProcess < ImporterBase
        def import!
          process = Decidim::ParticipatoryProcess.create!(
            organization:,
            title: parser.model_title(locales),
            slug: slugify(parser.model_title),
            subtitle: parser.model_subtitle(locales),
            short_description: parser.model_short_description(locales),
            description: parser.model_description(locales)
          )
          parser.components.each do |component_data|
            component_data[:participatory_space] = process
            Decidim::CommunityTemplates::Importers::Component.new(parser, organization, user, demo:).import!
          end
          process
        end
      end
    end
  end
end
