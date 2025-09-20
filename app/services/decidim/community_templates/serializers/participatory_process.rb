# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class ParticipatoryProcess < SerializerBase
        def manifest
          {
            name: "Participatory Process"
          }
        end

        def data
          {
            title: model.title,
            description: model.description
          }
        end

        def demo
          {
            title: {
              en: "Participatory Process Example"
            },
            description: {
              en: "This is an example of a participatory process."
            }
          }
        end
      end
    end
  end
end
