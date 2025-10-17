# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class ProposalState < SerializerBase
        def attributes
          {
            title: i18n_field(:title),
            announcement_title: i18n_field(:announcement_title),
            bg_color: model.bg_color,
            text_color: model.text_color,
            token: model.token
          }
        end
      end
    end
  end
end
