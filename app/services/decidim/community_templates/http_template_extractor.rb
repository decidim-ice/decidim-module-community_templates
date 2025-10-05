# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class HttpTemplateExtractor < TemplateExtractor
      def translations_path
        @translations_path ||= "#{template_path}/locales"
      end

      def dir_exists?(_path)
        return true #  directories make no sense in HTTP context
      end

      def read_file(path)
        response = Net::HTTP.get_response(URI.parse(join_url(template_path, path)))
        return "{}" if response.code.to_i >= 300

        response.body
      end

      def read_yml(path)
        response = Net::HTTP.get_response(URI.parse(join_url(template_path, path)))
        return {} if response.code.to_i >= 300

        YAML.load(response.body)
      end

      private

      def join_url(*paths)
        paths.first + paths[1..].map do |path|
          (path.start_with?("/") ? path : "/#{path}").chomp("/")
        end.join("/")
      end
    end
  end
end
