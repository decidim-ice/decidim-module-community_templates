# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class DisplayCondition < SerializerBase
        def attributes
          {
            condition_question: SerializerBase.id_for_model(model.condition_question),
            answer_option: SerializerBase.id_for_model(model.answer_option),
            condition_type: model.condition_type,
            condition_value: model.condition_value,
            mandatory: model.mandatory,
            created_at_relative: to_relative_date(model.created_at),
            updated_at_relative: to_relative_date(model.updated_at)
          }
        end
      end
    end
  end
end
