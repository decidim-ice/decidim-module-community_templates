# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplatesController < Decidim::CommunityTemplates::Admin::ApplicationController
        before_action do
          enforce_permission_to :read, :admin_dashboard
        end

        def index
          @template_form = form(Admin::TemplateForm).instance
        end
      end
    end
  end
end
