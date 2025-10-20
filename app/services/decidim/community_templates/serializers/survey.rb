# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Survey < SerializerBase
        def attributes
          {
            starts_at_relative: to_relative_date(model.starts_at),
            ends_at_relative: to_relative_date(model.ends_at),
            published_at_relative: to_relative_date(model.published_at),
            created_at_relative: to_relative_date(model.created_at),
            updated_at_relative: to_relative_date(model.updated_at),
            deleted_at_relative: to_relative_date(model.deleted_at),
            allow_answers: model.allow_answers,
            allow_unregistered: model.allow_unregistered,
            clean_after_publish: model.clean_after_publish,
            allow_editing_answers: model.allow_editing_answers,
            announcement: i18n_field(:announcement),
            questionnaire: questionnaire
          }
        end

        def questionnaire
          append_serializer(Serializers::Questionnaire, model.questionnaire, "questionnaire.#{SerializerBase.id_for_model(model.questionnaire)}")
        end
      end
    end
  end
end
