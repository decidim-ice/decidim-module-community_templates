# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Component < SerializerBase
        def attributes
          {
            name: i18n_field(:name)
          }
        end
      end
    end
  end
end
