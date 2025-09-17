# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      module ApplicationHelper
        def templates_list
          Dir.glob("#{Decidim::CommunityTemplates.local_templates_path}/*/template.json").map do |template_file|
            JSON.parse(File.read(template_file))
          end
        end

        def participatory_spaces
          spaces = {}
          Decidim.participatory_space_manifests.each do |manifest|
            participatory_spaces_list(manifest).each do |id, title|
              spaces[I18n.t("decidim.admin.menu.#{manifest.name}")] ||= {}
              spaces[I18n.t("decidim.admin.menu.#{manifest.name}")][id] = title
            end
          end
          spaces
        end

        def participatory_spaces_list(manifest)
          klass = manifest.model_class_name.safe_constantize
          return {} if klass.blank?

          klass.where(organization: current_organization).to_h do |item|
            [item.to_global_id, translated_attribute(item.title)]
          end
        end
      end
    end
  end
end
