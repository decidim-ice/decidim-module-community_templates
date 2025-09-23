# frozen_string_literal: true

Deface::Override.new(
  virtual_path: "decidim/participatory_processes/admin/participatory_processes/_process_row",
  name: "community_templates_add_participatory_processes_templates_icon",
  insert_top: ".table-list__actions",
  partial: "decidim/community_templates/admin/overrides/templatize_icon"
)
