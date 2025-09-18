# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class CatalogManifest
      include ActiveModel::Model
      include Decidim::AttributeObject::Model

      attribute :name, Symbol

      attribute :adapter, String

      # optional if using a custom class, otherwise inferred from `adapter`
      attribute :adapter_class, String

      attribute :options, Hash, default: {}

      def label
        instance.name || adapter.to_s.humanize
      end

      delegate :description, :version, to: :instance

      def import!
        instance.import!("#{CommunityTemplates.local_path}/#{name}")
      end

      def instance
        @instance ||= adapter_class.new(options)
      end

      def adapter_class
        return super if super.present?

        "Decidim::CommunityTemplates::CatalogAdapters::#{adapter.to_s.camelize}".constantize
      end
    end
  end
end
