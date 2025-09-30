# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    ##
    # Hold data about a catalog of templates.
    # Catalog is nothing more than a collection of templates.
    class Catalog
      include ActiveModel::Model
      include Decidim::AttributeObject::Model

      attribute :templates, Array[TemplateMetadata]
      validate :templates_are_valid

      def self.from_path(path)
        template_dirs = path.children.select do |child|
          # must be a directory in a uuid format
          child.directory? && child.basename.to_s.match?(TemplateMetadata::UUID_REGEX)
        end
        templates = template_dirs.map do |template_path|
          TemplateParser.new(template_path).template
        end
        model = new(
          templates: templates || []
        )
        model.validate!
        model
      end

      def active_templates
        templates.reject(&:archived?)
      end

      private

      def templates_are_valid
        templates.each do |template|
          next errors.add(:templates, :invalid) unless template.is_a?(TemplateMetadata)

          errors.add(:templates, :invalid) unless template.valid?
        end
      end
    end
  end
end
