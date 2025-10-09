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

          transaction do
            importer.import!
          end
          broadcast(:ok, importer.object)
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        private

        def importer
          @importer ||= form.importer.new(form.parser, organization, user)
        end
      end
    end
  end
end
