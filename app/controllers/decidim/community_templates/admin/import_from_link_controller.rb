# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    module Admin
      class ImportFromLinkController < ApplicationController
        def create
          raise InvalidRequestError unless request.xhr?

          @form = DirectLinkForm.from_params(params)
          @form.validate
          render partial: "direct_link_modal_form", locals: { form: @form }
        end
      end
    end
  end
end
