# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ProcessStep < ImporterBase
        def import!
          process_step_attributes = {
            participatory_process: @parent.object,
            title: required!(:title, parser.model_title(locales)),
            description: required!(:description, parser.model_description(locales)),
            start_date: from_relative_date(parser.attributes["start_date_relative"]),
            end_date: from_relative_date(parser.attributes["end_date_relative"]),
            position: @parent.object.steps.count + parser.model_position.to_i,
            active: @parent.object.steps.count.zero?
          }.compact
          @object = Decidim::ParticipatoryProcessStep.create!(process_step_attributes)
        end
      end
    end
  end
end
