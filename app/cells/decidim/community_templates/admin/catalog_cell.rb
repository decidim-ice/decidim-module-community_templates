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
