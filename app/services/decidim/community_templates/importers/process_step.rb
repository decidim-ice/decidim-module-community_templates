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
            end_date: from_relative_date(parser.attributes["end_date_relative"])
          }.compact
          @object = Decidim::ParticipatoryProcessStep.create!(process_step_attributes)
        end

        def from_relative_date(date)
          return nil if date.blank?

          Time.current + date.to_i
        end
      end
    end
  end
end
