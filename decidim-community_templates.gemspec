# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "decidim/community_templates/version"

Gem::Specification.new do |spec|
  spec.name = "decidim-community_templates"
  spec.version = Decidim::CommunityTemplates::VERSION
  spec.authors = ["Ivan Vergés", "Hadrien Froger"]
  spec.email = ["ivan@pokecode.net", "hadrien@octree.ch"]

  spec.summary = "Create and distribute templates from your participatory spaces"
  spec.description = "Create and distribute templates from your participatory spaces"
  spec.license = "AGPL-3.0"
  spec.homepage = "https://github.com/decidim-ice/decidim-module-community_templates"
  spec.required_ruby_version = ">= 3.3"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "decidim-admin", Decidim::CommunityTemplates::COMPAT_DECIDIM_VERSION
  spec.add_dependency "decidim-core", Decidim::CommunityTemplates::COMPAT_DECIDIM_VERSION
  spec.add_dependency "git", "4.0.5"
  spec.add_development_dependency "decidim-dev", Decidim::CommunityTemplates::COMPAT_DECIDIM_VERSION
  spec.add_development_dependency "decidim-participatory_processes", Decidim::CommunityTemplates::COMPAT_DECIDIM_VERSION
  spec.add_development_dependency "decidim-proposals", Decidim::CommunityTemplates::COMPAT_DECIDIM_VERSION
end
