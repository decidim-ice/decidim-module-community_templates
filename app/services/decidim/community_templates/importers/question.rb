# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Question < ImporterBase
        def import!
          question_attributes = {
            position: parser.model_position,
            question_type: parser.model_question_type,
            mandatory: parser.model_mandatory,
            body: parser.model_body(locales),
            description: parser.model_description(locales),
            created_at: from_relative_date(parser.attributes["created_at_relative"]),
            updated_at: from_relative_date(parser.attributes["updated_at_relative"]),
            max_choices: parser.model_max_choices,
            max_characters: parser.model_max_characters,
            survey_answers_published_at: from_relative_date(parser.attributes["survey_answers_published_at_relative"]),
            questionnaire: parent.object
          }
          @object = Decidim::Forms::Question.create!(question_attributes)
          @object.reload
        end

        def after_import!
          return if @object.nil?

          import_answer_options!
          import_matrix_rows!
          import_display_conditions!
        end

        def import_answer_options!
          (parser.attributes["answer_options"] || []).each do |answer_option_data|
            answer_option_parser = TemplateParser.new(
              data: answer_option_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars
            )
            serializer = Decidim::CommunityTemplates::Importers::AnswerOption.new(answer_option_parser, organization, user, parent: self)
            @after_import_serializers << serializer
            serializer.import!
          end
        end

        def import_matrix_rows!
          (parser.attributes["matrix_rows"] || []).each do |matrix_row_data|
            matrix_row_parser = TemplateParser.new(
              data: matrix_row_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars
            )
            serializer = Decidim::CommunityTemplates::Importers::MatrixRow.new(matrix_row_parser, organization, user, parent: self)
            @after_import_serializers << serializer
            serializer.import!
          end
        end

        def import_display_conditions!
          relations = parent.object.questions.index_by { |question| SerializerBase.id_for_model(question) }
          (parser.attributes["display_conditions"] || []).each do |display_condition_data|
            display_condition_parser = TemplateParser.new(
              data: display_condition_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars,
              relations: relations
            )
            serializer = Decidim::CommunityTemplates::Importers::DisplayCondition.new(display_condition_parser, organization, user, parent: self)
            @after_import_serializers << serializer
            serializer.import!
          end
        end
      end
    end
  end
end
