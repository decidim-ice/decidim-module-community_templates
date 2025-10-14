# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class ParticipatoryProcess < ImporterBase
        attr_reader :created_steps

        def import!
          parser.populate_i18n_vars!(organization)
          participatory_process_attributes = {
            organization:,
            title: required!(:title, parser.model_title(locales)),
            slug: slugify(parser.model_title),
            subtitle: required!(:subtitle, parser.model_subtitle(locales)),
            short_description: required!(:short_description, parser.model_short_description(locales)),
            description: required!(:description, parser.model_description(locales)),
            announcement: parser.model_announcement(locales),
            start_date: from_relative_date(parser.attributes["start_date_relative"]),
            end_date: from_relative_date(parser.attributes["end_date_relative"]),
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
          after_import!
          @object
        end

        def after_import!
          import_steps!
          import_components!
          import_hero_image!
          import_content_blocks!
          after_import_serializers.each(&:after_import!)
          @object.save!
          @object.reload
        end

        def import_hero_image!
          attach!(parser.attributes["hero_image"], "hero_image") if parser.attributes["hero_image"]
        end

        def import_content_blocks!
          parser.attributes["content_blocks"]&.each do |content_block_data|
            content_block_parser = TemplateParser.new(
              data: content_block_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars
            )
            content_block_serializer = Decidim::CommunityTemplates::Importers::ContentBlock.new(content_block_parser, organization, user, parent: self)
            content_block_serializer.import!
            @after_import_serializers << content_block_serializer
          end
        end

        def import_components!
          parser.attributes["components"]&.each do |component_data|
            template_parser_attributes = {
              data: component_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars
            }.compact
            component_parser = TemplateParser.new(**template_parser_attributes)
            component_serializer = Decidim::CommunityTemplates::Importers::Component.new(component_parser, organization, user, parent: self)
            component_serializer.import!
            @after_import_serializers << component_serializer
          end
        end

        def import_steps!
          @created_steps = {}
          parser.attributes["steps"]&.each do |step_data|
            step_parser = TemplateParser.new(
              data: step_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars
            )
            step_serializer = Decidim::CommunityTemplates::Importers::ProcessStep.new(step_parser, organization, user, parent: self)
            created_steps[step_data["id"].split(".").last] = step_serializer.import!
            @after_import_serializers << step_serializer
          end
        end
      end
    end
  end
end
