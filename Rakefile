# frozen_string_literal: true

require "decidim/dev/common_rake"

def seed_db(path)
  Dir.chdir(path) do
    system("bundle exec rake db:seed")
  end
end

desc "Generates a dummy app for testing"
task :test_app do
  ENV["RAILS_ENV"] = "test"
  generate_decidim_app(
    "spec/decidim_dummy_app",
    "--app_name",
    "#{base_app_name}_test_app",
    "--path",
    "../..",
    "--recreate_db",
    "--skip_gemfile",
    "--skip_spring",
    "--demo",
    "--force_ssl",
    "false",
    "--locales",
    "en,ca,es,pt-BR"
  )
end

desc "Generates a development app."
task :development_app do
  Bundler.with_original_env do
    generate_decidim_app(
      "development_app",
      "--app_name",
      "#{base_app_name}_development_app",
      "--path",
      "..",
      "--recreate_db",
      "--demo"
    )
  end

  seed_db("development_app")
end
