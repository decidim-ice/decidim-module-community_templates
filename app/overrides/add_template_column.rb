# frozen_string_literal: true

Deface::Override.new(
  virtual_path: "decidim/participatory_processes/admin/participatory_processes/_process_row",
  name: "community_templates_add_participatory_processes_templates_column",
  insert_before: ".table-list__date",
  partial: "decidim/community_templates/admin/overrides/template_column"
)
Deface::Override.new(
  virtual_path: "decidim/participatory_processes/admin/participatory_processes/_processes_thead",
  name: "community_templates_add_participatory_processes_templates_thead",
  insert_after: "thead tr th:first-child",
  partial: "decidim/community_templates/admin/overrides/template_thead"
)
