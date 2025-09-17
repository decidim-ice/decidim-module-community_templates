# frozen_string_literal: true

require "spec_helper"

module Decidim
  module CommunityTemplates
    module Admin
      describe TemplateForm, type: :form do
        subject { described_class.new }

        it { is_expected.to be_valid }
      end
    end
  end
end
