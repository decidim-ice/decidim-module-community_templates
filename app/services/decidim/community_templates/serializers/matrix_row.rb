# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class MatrixRow < SerializerBase
        def attributes
          {
            body: i18n_field(:body),
            position: model.position
          }
        end
      end
    end
  end
end
