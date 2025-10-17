# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ProposalState < ImporterBase
        def import!
          proposal_state_attributes = {
            title: required!(:title, parser.model_title(locales)),
            announcement_title: parser.model_announcement_title(locales),
            bg_color: parser.model_bg_color,
            text_color: parser.model_text_color,
            token: required!(:token, parser.model_token),
            component: parent.object
          }
          @object = Decidim::Proposals::ProposalState.create!(proposal_state_attributes)
        end
      end
    end
  end
end
