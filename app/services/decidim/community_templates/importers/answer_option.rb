# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class AnswerOption < ImporterBase
        def import!
          answer_option_attributes = {
            body: parser.model_body(locales),
            free_text: parser.model_free_text,
            question: parent.object
          }
          @object = Decidim::Forms::AnswerOption.create!(answer_option_attributes)
          @object.save!
          @object.reload
        end
      end
    end
  end
end
