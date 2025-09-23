# frozen_string_literal: true

base_path = File.expand_path("..", __dir__)

Decidim::Webpacker.register_path("#{base_path}/app/packs")
Decidim::Webpacker.register_entrypoints(
  decidim_admin_community_templates: "#{base_path}/app/packs/entrypoints/decidim_admin_community_templates.js"
)
Decidim::Webpacker.register_stylesheet_import("stylesheets/decidim/community_templates/admin/admin")
