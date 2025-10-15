# frozen_string_literal: true

require "redcarpet"
module Decidim
  module CommunityTemplates
    module Admin
      class CatalogCell < Decidim::ViewModel
        include Decidim::TooltipHelper
        alias catalog model

        def show
          render
        end

        private

        def tooltip_usages_for(template_id)
          usages_for(template_id).map do |usage|
            "<span>#{decidim_escape_translated(usage.resource.title)}</span>"
          end.join("<br />").html_safe
        end

        def usages_for(template_id)
          Decidim::CommunityTemplates::TemplateUse.where(template_id: template_id)
        end

        def usages_count(template_id)
          usages_for(template_id).count
        end

        def host_for(url)
          URI.parse(normalize_url(url)).host
        end

        def normalize_url(url)
          # add https:// if not present
          url = "https://#{url}" unless url.start_with?("http")
          # remove trailing slash
          url.chomp("/")
        end

        def cache_hash
          nil
        end

        def markdown_to_html(text)
          markdown.render(text)
        end

        def markdown
          @markdown ||= ::Decidim::Comments::Markdown.new
        end
      end
    end
  end
end
