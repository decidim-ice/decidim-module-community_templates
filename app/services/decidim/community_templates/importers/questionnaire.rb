# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Questionnaire < ImporterBase
        def import!
          questionnaire_attributes = {
            title: parser.model_title(locales),
            description: parser.model_description(locales),
            tos: parser.model_tos(locales),
            published_at: from_relative_date(parser.attributes["published_at_relative"]),
            created_at: from_relative_date(parser.attributes["created_at_relative"]),
            updated_at: from_relative_date(parser.attributes["updated_at_relative"]),
            questionnaire_for: parent.object
          }
          @object = Decidim::Forms::Questionnaire.create!(questionnaire_attributes)
          @object.reload
        end

        def after_import!
          return if @object.nil?

          import_questions!
          @after_import_serializers.each(&:after_import!)
        end

        def import_questions!
          (parser.attributes["questions"] || []).each do |question_data|
            question_parser = TemplateParser.new(
              data: question_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars
            )

            serializer = Decidim::CommunityTemplates::Importers::Question.new(question_parser, organization, user, parent: self)
            @after_import_serializers << serializer
            serializer.import!
          end
        end
      end
    end
  end
end
