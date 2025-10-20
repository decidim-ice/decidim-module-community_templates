# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class DisplayCondition < ImporterBase
        def import!
          condition_question = parser.relations[parser.model_condition_question]
          return unless condition_question

          display_condition_attributes = {
            condition_question: condition_question,
            answer_option: parser.model_answer_option,
            condition_type: parser.model_condition_type,
            condition_value: parser.model_condition_value,
            mandatory: parser.model_mandatory,
            created_at: from_relative_date(parser.attributes["created_at_relative"]),
            updated_at: from_relative_date(parser.attributes["updated_at_relative"]),
            question: parent.object
          }
          @object = Decidim::Forms::DisplayCondition.create!(display_condition_attributes)
          @object.save!
          @object.reload
        end
      end
    end
  end
end
