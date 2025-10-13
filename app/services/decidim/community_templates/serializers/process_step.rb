# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class ProcessStep < SerializerBase
        def attributes
          {
            title: i18n_field(:title),
            description: i18n_field(:description),
            start_date_relative: model.start_date ? Time.current.to_i - model.start_date.to_i : nil,
            end_date_relative: model.end_date ? Time.current.to_i - model.end_date.to_i : nil
          }
        end
      end
    end
  end
end
