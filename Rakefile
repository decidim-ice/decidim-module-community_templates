# frozen_string_literal: true

require "decidim/dev/common_rake"

def seed_db(path)
  Dir.chdir(path) do
    system("bundle exec rails db:migrate", exception: true)
    system("bundle exec rake db:seed", exception: true)
  end
end

def prepare_test_files
  Dir.chdir("spec/decidim_dummy_app") do
    database_yml = {
      "test" => {
        "adapter" => "postgresql",
        "encoding" => "unicode",
        "host" => ENV.fetch("DATABASE_HOST", "localhost"),
        "port" => ENV.fetch("DATABASE_PORT", "5432").to_i,
        "username" => ENV.fetch("DATABASE_USERNAME", "decidim"),
        "password" => ENV.fetch("DATABASE_PASSWORD", "insecure-password"),
        "database" => "community_template<%= ENV.fetch('TEST_ENV_NUMBER', '') %>",
        "schema_search_path" => "public,shared_extensions"
      },
      "development" => {
        "adapter" => "postgresql",
        "encoding" => "unicode",
        "host" => ENV.fetch("DATABASE_HOST", "localhost"),
        "port" => ENV.fetch("DATABASE_PORT", "5432").to_i,
        "username" => ENV.fetch("DATABASE_USERNAME", "decidim"),
        "password" => ENV.fetch("DATABASE_PASSWORD", "insecure-password"),
        "database" => "community_template_dev",
        "schema_search_path" => "public,shared_extensions"
      }
    }
    File.open("config/database.yml", "w") { |f| YAML.dump(database_yml, f) }

    # Ensure preconditions for rspec with apartment:
    # 1. gem installed
    # 2. db created,migrated and dumped
    # 3. assets precompiled
    system("bundle check || bundle install")
    system("bundle exec rails db:environment:set RAILS_ENV=#{ENV["RAILS_ENV"]}") if ENV["RAILS_ENV"]
    system("bundle exec rails db:drop", exception: true)
    system("bundle exec rails db:create", exception: true)
    if ENV["TEMPLATE_TEST_APARTMENT"]
      system("bundle exec rails decidim_apartment:install_pg_extension")
      system("bundle exec rails decidim_apartment:install:migrations")
    end
    system("bundle exec rails db:migrate", exception: true)

    system("bundle exec rails db:schema:dump", exception: true)
    system("npm install", exception: true)
    system("bundle exec rails assets:precompile", exception: true)
  end
end

desc "Generates a dummy app for testing"
task :test_app do
  raise "Must be in development" unless Rails.env.development?

  Bundler.with_original_env do
    generate_decidim_app(
      "spec/decidim_dummy_app",
      "--app_name",
      "DecidimCommunityTemplates",
      "--path",
      "../..",
      "--skip_spring",
      "--demo",
      "--force_ssl",
      "false",
      "--locales",
      "en,ca,es,pt-BR"
    )
  end
  prepare_test_files
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
      "--demo",
      "--locales",
      "en,ca,es,es-MX,pt-BR,fr"
    )
  end

  seed_db("development_app")
end
