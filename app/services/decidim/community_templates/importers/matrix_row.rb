# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class MatrixRow < ImporterBase
        def import!
          matrix_row_attributes = {
            body: parser.model_body(locales),
            position: parser.model_position,
            question: parent.object
          }
          @object = Decidim::Forms::QuestionMatrixRow.create!(matrix_row_attributes)
          @object.save!
          @object.reload
        end
      end
    end
  end
end
