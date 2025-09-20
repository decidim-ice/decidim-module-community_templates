# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module SpecHelpers
      module RunInitializer
        def run_initializer!(initializer_name)
          initializer = Decidim::CommunityTemplates::Engine.initializers.find { |i| i.name == initializer_name }
          initializer.run
        end
      end
    end
  end
end
