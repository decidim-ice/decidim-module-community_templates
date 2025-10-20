# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Questionnaire < SerializerBase
        def attributes
          {
            title: i18n_field(:title),
            description: i18n_field(:description),
            tos: i18n_field(:tos),
            published_at_relative: to_relative_date(model.published_at),
            created_at_relative: to_relative_date(model.created_at),
            updated_at_relative: to_relative_date(model.updated_at),
            questions: questions
          }
        end

        def questions
          @questions ||= model.questions.map do |question|
            append_serializer(Serializers::Question, question, "questions.#{SerializerBase.id_for_model(question)}")
          end
        end
      end
    end
  end
end
