# frozen_string_literal: true

Deface::Override.new(
  virtual_path: "layouts/decidim/admin/_header",
  name: "add_admin_assets",
  insert_before: "erb[loud]:contains('javascript_pack_tag \"decidim_core\"')",
  text: "
    <%= append_javascript_pack_tag 'decidim_admin_community_templates' %>
  "
)
