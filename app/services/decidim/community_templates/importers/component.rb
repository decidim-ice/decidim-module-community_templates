# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ParticipatoryProcess < ImporterBase
        def import!
          Decidim::Component.create!(
            participatory_space:,
            name: parser.model_name(locales)
          )
        end
      end
    end
  end
end
