# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Question < SerializerBase
        def attributes
          {
            position: model.position,
            question_type: model.question_type,
            mandatory: model.mandatory,
            body: i18n_field(:body),
            description: i18n_field(:description),
            created_at_relative: to_relative_date(model.created_at),
            updated_at_relative: to_relative_date(model.updated_at),
            max_choices: model.max_choices,
            max_characters: model.max_characters,
            survey_answers_published_at_relative: to_relative_date(model.survey_answers_published_at),
            answer_options: answer_options,
            matrix_rows: matrix_rows,
            display_conditions: display_conditions
          }
        end

        def answer_options
          model.answer_options.map do |answer_option|
            append_serializer(Serializers::AnswerOption, answer_option, "answer_options.#{SerializerBase.id_for_model(answer_option)}")
          end
        end

        def matrix_rows
          model.matrix_rows.map do |matrix_row|
            append_serializer(Serializers::MatrixRow, matrix_row, "matrix_rows.#{SerializerBase.id_for_model(matrix_row)}")
          end
        end

        def display_conditions
          model.display_conditions.map do |display_condition|
            append_serializer(Serializers::DisplayCondition, display_condition, "display_conditions.#{SerializerBase.id_for_model(display_condition)}")
          end
        end
      end
    end
  end
end
