# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ParticipatoryProcess < ImporterBase
        def import!
          participatory_process_attributes = {
            organization:,
            title: required!(:title, parser.model_title(locales)),
            slug: slugify(parser.model_title),
            subtitle: required!(:subtitle, parser.model_subtitle(locales)),
            short_description: required!(:short_description, parser.model_short_description(locales)),
            description: required!(:description, parser.model_description(locales)),
            announcement: parser.model_announcement(locales),
            start_date: parser.model_start_date,
            end_date: parser.model_end_date,
            developer_group: parser.model_developer_group(locales),
            local_area: parser.model_local_area(locales),
            meta_scope: parser.model_meta_scope(locales),
            target: parser.model_target(locales),
            participatory_scope: parser.model_participatory_scope(locales),
            participatory_structure: parser.model_participatory_structure(locales),
            private_space: parser.model_private_space,
            promoted: parser.model_promoted
          }.compact
          @object = Decidim::ParticipatoryProcess.create!(participatory_process_attributes)
          parser.attributes["components"]&.each do |component_data|
            template_parser_attributes = {
              data: component_data,
              translations: parser.translations,
              locales: parser.locales
            }.compact
            component_parser = TemplateParser.new(**template_parser_attributes)
            Decidim::CommunityTemplates::Importers::Component.new(component_parser, organization, user, parent: self).import!
          end
          @object
        end
      end
    end
  end
end
