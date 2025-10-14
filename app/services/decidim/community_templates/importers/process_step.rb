module Decidim
  module CommunityTemplates
    module Importers
      class ProcessStep < ImporterBase
        def import!
          step_attributes = {
            participatory_process: parent.object,
            title: required!(:title, parser.model_title(locales)),
            description: required!(:description, parser.model_description(locales)),
            start_date: relative_date(parser.attributes["start_date_relative"]),
            end_date: relative_date(parser.attributes["end_date_relative"]),
          }.compact
          @object = Decidim::ParticipatoryProcessStep.create!(step_attributes)
        end
      end
    end
  end
end