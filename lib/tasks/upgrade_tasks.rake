# frozen_string_literal: true

Rake::Task["decidim:choose_target_plugins"].enhance do
  ENV["FROM"] = "#{ENV.fetch("FROM", nil)},decidim_community_templates"
end

Rake::Task["decidim:update"].enhance do
  Rake::Task["decidim_community_templates:install:migrations"].invoke
end
