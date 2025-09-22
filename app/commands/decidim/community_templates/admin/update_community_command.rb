# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class UpdateCommunityCommand < Decidim::Command
        attr_reader :form

        def initialize(form)
          @form = form
        end

        def call
          return broadcast(:invalid) if form.invalid?

          form.template.owned = true
          form.template.write(Decidim::CommunityTemplates.catalog_path)
          broadcast(:ok)
        rescue StandardError
          broadcast(:invalid)
        end
      end
    end
  end
end
