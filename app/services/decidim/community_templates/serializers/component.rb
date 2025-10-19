# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Serializers
      class Component < SerializerBase
        def attributes
          {
            manifest_name: model.manifest_name,
            name: i18n_field(:name),
            global_settings: global_settings,
            step_settings: step_settings,
            default_step_settings: default_step_settings,
            weight: model.weight,
            published_at_relative: to_relative_date(model.published_at),
            resources: resources
          }
        end

        def global_settings
          model.manifest.settings(:global).attributes.map do |type, value|
            {
              type: type.to_s,
              value: setting_value(model.settings[type], key: type, manifest: value, scope: "global")
            }
          end
        end

        def default_step_settings
          model.manifest.settings(:default_step).attributes.map do |type, value|
            {
              type: type.to_s,
              value: setting_value(model.default_step_settings[type], key: type, manifest: value, scope: "default_step")
            }
          end
        end

        def step_settings
          step = model.step_settings
          step.to_h do |step_key, step_value|
            step = Decidim::ParticipatoryProcessStep.find(step_key)
            serialized_key = SerializerBase.id_for_model(step)
            [
              serialized_key,
              model.manifest.settings(:step).attributes.map do |type, value|
                {
                  type: type.to_s,
                  value: setting_value(step_value[type], key: type.to_s, manifest: value, scope: "steps_#{serialized_key}")
                }
              end
            ]
          end.to_h
        end

        def setting_value(setting_value, key:, manifest:, scope:)
          setting_value = i18n_field(key, setting_value, "#{scope}_settings") if manifest.translated?
          setting_value = !setting_value.nil? && setting_value if manifest.type == :boolean
          setting_value
        end

        def resources
          case model.manifest_name
          when "proposals"
            Decidim::Proposals::ProposalState.where(component: model).map do |proposal_state|
              append_serializer(Serializers::ProposalState, proposal_state, "proposal_states.#{SerializerBase.id_for_model(proposal_state)}")
            end + Decidim::Proposals::Proposal.unscoped.where(component: model).map do |proposal|
              append_serializer(Serializers::Proposal, proposal, "proposals.#{SerializerBase.id_for_model(proposal)}")
            end
          when "pages"
            Decidim::Pages::Page.unscoped.where(component: model).map do |page|
              append_serializer(Serializers::Page, page, "pages.#{SerializerBase.id_for_model(page)}")
            end
          else
            []
          end
        end
      end
    end
  end
end
