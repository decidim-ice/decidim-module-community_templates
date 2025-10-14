module Decidim
  module CommunityTemplates
    module Serializers
      class ProcessStep < SerializerBase
        def attributes
          {
            title: i18n_field(:title),
            description: i18n_field(:description),
            start_date_relative: relative_date(model.start_date),
            end_date_relative: relative_date(model.end_date),
          }
        end


      end
    end
  end
end