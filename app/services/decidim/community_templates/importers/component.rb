# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Importers
      class Component < ImporterBase
        def import!
          component_attributes = {
            participatory_space: parent.object,
            name: required!(:name, parser.model_name(locales)),
            manifest_name: required!(:manifest_name, parser.model_manifest_name),
            weight: parser.model_weight,
            published_at: from_relative_date(parser.attributes["published_at_relative"])
          }.compact
          @object = Decidim::Component.create!(component_attributes)
          @object.settings = global_settings
          @object.step_settings = step_settings
          @object.default_step_settings = default_step_settings

          @object.save!
          @object.reload
        end

        def after_import!
          return if @object.nil?

          import_resources!
          after_import_serializers.each(&:after_import!)
        end

        def import_resources!
          case parser.model_manifest_name
          when "proposals"
            proposal_states = import_proposal_states!
            import_proposals!(proposal_states) if demo?
          end
        end

        def import_proposal_states!
          (parser.attributes["resources"] || []).select { |resource| resource["@class"] == "Decidim::Proposals::ProposalState" }.map do |proposal_state_data|
            proposal_state_parser = TemplateParser.new(
              data: proposal_state_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars
            )
            serializer = Decidim::CommunityTemplates::Importers::ProposalState.new(proposal_state_parser, organization, user, parent: self, for_demo: demo?)
            @after_import_serializers << serializer
            serializer.import!
          end
        end

        def import_proposals!(proposal_states)
          return unless demo?
          relations = proposal_states.reduce({}) do |acc, state|
            acc[SerializerBase.id_for_model(state)] = state
            acc 
          end
          (parser.attributes["resources"] || []).select { |resource| resource["@class"] == "Decidim::Proposals::Proposal" }.each do |proposal_data|
            proposal_parser = TemplateParser.new(
              data: proposal_data,
              translations: parser.translations,
              locales: parser.locales,
              assets: parser.assets,
              i18n_vars: parser.i18n_vars,
              relations: relations
            )
            serializer = Decidim::CommunityTemplates::Importers::Proposal.new(proposal_parser, organization, user, parent: self, for_demo: demo?)
            serializer.import!
            @after_import_serializers << serializer
          end
        end

        def default_step_settings
          (parser.attributes["default_step_settings"] || []).to_h do |key_value|
            key_value_to_hash(key_value)
          end
        end

        def global_settings
          (parser.attributes["global_settings"] || []).to_h do |key_value|
            key_value_to_hash(key_value)
          end
        end

        def step_settings
          settings = parser.attributes["step_settings"] || {}
          settings.to_h do |step_key, step_settings|
            step = parent_steps[step_key]
            next [] unless step

            [
              step.id,
              step_settings.to_h do |key_value|
                key_value_to_hash(key_value)
              end
            ]
          end
        end

        def key_value_to_hash(key_value)
          key = key_value["type"]
          value = key_value["value"]
          if value.is_a?(String) && value.start_with?("#{parser.id}.") && value.end_with?("_settings.#{key}")
            value = parser.all_translations_for(value, locales,
                                                ignore_missing: true)
          end
          [key, value]
        end

        def parent_steps
          @parent_steps ||= parent.created_steps
        end
      end
    end
  end
end
