# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class SerializerManifest
      include ActiveModel::Model
      include Decidim::AttributeObject::Model

      attribute :name, Symbol

      attribute :serializer, String
      attribute :model, String
      attribute :options, Hash, default: {}

      def serializer_class
        @serializer_class ||= serializer.constantize
      end
    end
  end
end
