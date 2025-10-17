# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Proposal < ImporterBase
        def import!
          return unless demo?
          proposal_attributes = {
            title: parser.model_title(locales),
            body: parser.model_body(locales),
            created_at: from_relative_date(parser.attributes["created_at_relative"]),
            updated_at: from_relative_date(parser.attributes["updated_at_relative"]),
            answered_at: from_relative_date(parser.attributes["answered_at_relative"]),
            answer: parser.model_answer(locales, ignore_missing: true),
            reference: parser.model_reference,
            address: parser.model_address,
            latitude: parser.model_latitude,
            longitude: parser.model_longitude,
            published_at: from_relative_date(parser.attributes["published_at_relative"]),
            participatory_text_level: parser.model_participatory_text_level,
            position: parser.model_position,
            endorsements_count: parser.model_endorsements_count,
            cost: parser.model_cost,
            cost_report: parser.model_cost_report(locales),
            execution_period: parser.model_execution_period(locales),
            proposal_state: find_proposal_state,
            component: parent.object
          }
          proposal = Decidim::Proposals::Proposal.new(proposal_attributes)
          proposal.save(validate: false)
          proposal.coauthorships.create!(author: dummy_users.pick_one, decidim_author_type: "Decidim::UserBaseEntity")
          proposal.save!
          @object = proposal.reload
        end

        def after_import!
          return unless demo?

          fake_votes!
        end

        def fake_votes!
          return unless demo?
          return if parser.model_proposal_votes_count.zero?

          fake_users = dummy_users.pick_sample(parser.model_proposal_votes_count)
          fake_users.each do |fake_user|
            Decidim::Proposals::ProposalVote.create!(
              proposal: @object,
              author: fake_user,
              temporary: false
            )
          end
        end

        def find_proposal_state
          serialized_id = parser.attributes["state_id"]
          return nil if serialized_id.blank?
          parser.relations[serialized_id]
        end
      end
    end
  end
end
