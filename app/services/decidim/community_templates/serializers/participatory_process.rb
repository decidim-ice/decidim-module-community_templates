# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class ParticipatoryProcess < SerializerBase
        def data
          super.merge(
            title: i18n_field(:title),
            description: i18n_field(:description)
          )
        end
      end
    end
  end
end
