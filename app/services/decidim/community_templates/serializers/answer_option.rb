# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class AnswerOption < SerializerBase
        def attributes
          {
            body: i18n_field(:body),
            free_text: model.free_text
          }
        end
      end
    end
  end
end
