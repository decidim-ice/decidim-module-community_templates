# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class ImportTemplate < Decidim::Command
        def initialize(form)
          @form = form
          @organization = form.context.current_organization
          @user = form.context.current_user
        end
        attr_reader :form, :organization, :user

        def call
          return broadcast(:invalid, form.errors.full_messages.to_sentence) if form.invalid?

          importer.import!
          broadcast(:ok)
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        private

        def importer
          @importer ||= "Decidim::CommunityTemplates::Importers::#{importer_class}".constantize.new(form.parser, organization, user, demo: form.demo)
        end

        # a very naive way to get the importer class from the metadata
        # we might want to create a registry of importers instead
        def importer_class
          form.parser.metadata["class"].split("::").last
        end
      end
    end
  end
end
