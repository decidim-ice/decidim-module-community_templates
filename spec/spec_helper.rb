# frozen_string_literal: true

require "decidim/dev"

ENV["ENGINE_ROOT"] = File.dirname(__dir__)
ENV["NODE_ENV"] ||= "test"

Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "decidim_dummy_app"))

require "decidim/dev/test/base_spec_helper"
RSpec.configure do |config|
  # Make "pt-BR" locale available in tests.
  config.before do
    I18n.available_locales = [:en, :ca, :"pt-BR"]
    Decidim.available_locales = [:en, :ca, :"pt-BR"]
    Decidim.default_locale = :en
  end

  config.around do |example|
    I18n.with_locale(:en) { example.run }
  end
end
