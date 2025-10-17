# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Proposal < SerializerBase
        def attributes
          {
            title: i18n_field(:title),
            body: i18n_field(:body),
            created_at_relative: to_relative_date(model.created_at),
            updated_at_relative: to_relative_date(model.updated_at),
            proposal_votes_count: model.proposal_votes_count,
            answered_at_relative: to_relative_date(model.answered_at),
            answer: i18n_field(:answer),
            reference: model.reference,
            address: model.address,
            latitude: model.latitude,
            longitude: model.longitude,
            published_at_relative: to_relative_date(model.published_at),
            participatory_text_level: model.participatory_text_level,
            position: model.position,
            endorsements_count: model.endorsements_count,
            cost: model.cost,
            cost_report: i18n_field(:cost_report),
            execution_period: i18n_field(:execution_period),
            state_id: SerializerBase.id_for_model(model.proposal_state),
            state_published_at_relative: to_relative_date(model.state_published_at),
            withdrawn_at_relative: to_relative_date(model.withdrawn_at),
            deleted_at_relative: to_relative_date(model.deleted_at)
          }
        end
      end
    end
  end
end
