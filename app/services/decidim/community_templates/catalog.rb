# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    ##
    # Hold data about a catalog of templates.
    # Catalog is nothing more than a collection of templates.
    class Catalog
      include ActiveModel::Model
      include Decidim::AttributeObject::Model

      attribute :templates, Array[Template]
      validate :templates_are_valid

      def self.from_path(path)
        template_dirs = path.children.select do |child|
          # must be a directory in a uuid format
          child.directory? && child.basename.to_s.match?(Template::UUID_REGEX)
        end
        templates = template_dirs.map do |template_path|
          Template.from_path(template_path)
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

      def write(path)
        raise ActiveModel::ValidationError, self unless valid?

        FileUtils.mkdir_p(path)
        # Write the templates, one folder per template
        templates.each do |template|
          template.write(path)
        end
      end

      private

      def templates_are_valid
        templates.each do |template|
          next errors.add(:templates, :invalid) unless template.is_a?(Template)

          errors.add(:templates, :invalid) unless template.valid?
        end
      end
    end
  end
end
