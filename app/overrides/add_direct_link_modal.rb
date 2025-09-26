# frozen_string_literal: true

Deface::Override.new(
  virtual_path: "layouts/decidim/admin/_js_configuration",
  name: "community_templates_add_direct_link_modal",
  insert_after: "script",
  partial: "decidim/community_templates/admin/import_from_link/form"
)
