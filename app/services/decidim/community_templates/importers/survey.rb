# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Survey < ImporterBase
        def import!
          survey_attributes = {
            starts_at: from_relative_date(parser.attributes["starts_at_relative"]),
            ends_at: from_relative_date(parser.attributes["ends_at_relative"]),
            published_at: from_relative_date(parser.attributes["published_at_relative"]),
            created_at: from_relative_date(parser.attributes["created_at_relative"]),
            updated_at: from_relative_date(parser.attributes["updated_at_relative"]),
            deleted_at: from_relative_date(parser.attributes["deleted_at_relative"]),
            allow_answers: parser.model_allow_answers,
            allow_unregistered: parser.model_allow_unregistered,
            clean_after_publish: parser.model_clean_after_publish,
            allow_editing_answers: parser.model_allow_editing_answers,
            announcement: parser.model_announcement(locales),
            component: parent.object
          }
          @object = Decidim::Surveys::Survey.new(survey_attributes)
          # save without questionnaire
          @object.save(validate: false)
          @object.reload
        end

        def after_import!
          return if @object.nil?

          import_questionnaire!
          @object.reload
          @after_import_serializers.each(&:after_import!)
        end

        def import_questionnaire!
          questionnaire_parser = TemplateParser.new(
            data: parser.attributes["questionnaire"],
            translations: parser.translations,
            locales: parser.locales,
            assets: parser.assets,
            i18n_vars: parser.i18n_vars
          )
          serializer = Decidim::CommunityTemplates::Importers::Questionnaire.new(questionnaire_parser, organization, user, parent: self)
          @after_import_serializers << serializer
          serializer.import!
        end
      end
    end
  end
end
