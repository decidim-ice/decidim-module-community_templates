# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class InvalidModelsCleaner
      def initialize(catalog_path, apartment_strategy: nil)
        @catalog_path = catalog_path
        @apartment_strategy = apartment_strategy
      end

      def call
        if @apartment_strategy
          @apartment_strategy.each_tenant do
            remove_invalid_models!
          end
        else
          remove_invalid_models!
        end
      end

      private

      def remove_invalid_models!
        templates = @catalog_path.children.select do |d|
          d.directory? && d.basename.to_s.match?(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
        end
        template_ids = templates.map { |path| path.basename.to_s }
        Decidim::CommunityTemplates::TemplateSource.where.not(template_id: template_ids).destroy_all
        Decidim::CommunityTemplates::TemplateUse.where.not(template_id: template_ids).destroy_all
      end
    end
  end
end
