# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Page < ImporterBase
        def import!
          page_attributes = {
            body: required!(:body, parser.model_body(locales)),
            component: parent.object,
            created_at: from_relative_date(parser.attributes["created_at_relative"]),
            updated_at: from_relative_date(parser.attributes["updated_at_relative"]),
            deleted_at: from_relative_date(parser.attributes["deleted_at_relative"])
          }
          @object = Decidim::Pages::Page.create!(page_attributes)
        end
      end
    end
  end
end
