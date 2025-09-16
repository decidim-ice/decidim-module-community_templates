# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class TemplateForm < Decidim::Form
        attribute :participatory_space, Array
      end
    end
  end
end
