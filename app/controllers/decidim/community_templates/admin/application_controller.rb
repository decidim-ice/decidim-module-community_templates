# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class ApplicationController < Decidim::Admin::ApplicationController
        def permission_class_chain
          [::Decidim::CommunityTemplates::Admin::Permissions] + super
        end

        before_action do
          enforce_permission_to :update, :organization, organization: current_organization
        end
      end
    end
  end
end
