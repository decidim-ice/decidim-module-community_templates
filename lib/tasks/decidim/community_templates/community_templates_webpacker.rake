# frozen_string_literal: true

require "decidim/gem_manager"

namespace :decidim_community_templates do
  namespace :webpacker do
    desc "Installs Community Templates webpacker files in Rails instance application"
    task install: :environment do
      raise "Decidim gem is not installed" if decidim_path.nil?

      install_community_templates_npm
    end

    desc "Adds Community Templates dependencies in package.json"
    task upgrade: :environment do
      raise "Decidim gem is not installed" if decidim_path.nil?

      install_community_templates_npm
    end

    def install_community_templates_npm
      return if community_templates_npm_dependencies.empty?

      puts "install NPM packages. You can also do this manually with this command:"
      puts "npm i #{community_templates_npm_dependencies.join(" ")}"
      community_templates_system! "npm i #{community_templates_npm_dependencies.join(" ")}"
    end

    def community_templates_npm_dependencies
      @community_templates_npm_dependencies ||= begin
        return [] if community_templates_path.nil? || !File.exist?(community_templates_path.join("package.json"))

        package_json = JSON.parse(File.read(community_templates_path.join("package.json")))

        (package_json["dependencies"] || {}).map { |package, version| "#{package}@#{version}" }
      end
    end

    def community_templates_path
      @community_templates_path ||= Pathname.new(community_templates_gemspec.full_gem_path) if Gem.loaded_specs.has_key?(community_templates_gem_name)
    end

    def rails_app_path
      @rails_app_path ||= Rails.root
    end

    def community_templates_system!(command)
      system("cd #{rails_app_path} && #{command}") || abort("\n== Command #{command} failed ==")
    end

    def community_templates_gemspec
      @community_templates_gemspec ||= Gem.loaded_specs[community_templates_gem_name]
    end

    def community_templates_gem_name
      "decidim-community_templates"
    end
  end
end

