# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Page < SerializerBase
        def attributes
          {
            body: i18n_field(:body),
            created_at_relative: to_relative_date(model.created_at),
            updated_at_relative: to_relative_date(model.updated_at),
            deleted_at_relative: to_relative_date(model.deleted_at)
          }
        end
      end
    end
  end
end
