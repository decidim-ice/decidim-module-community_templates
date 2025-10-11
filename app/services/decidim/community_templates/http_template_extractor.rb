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
        file_content = self.class.fetch(join_url(template_path, path))
        file_content || "{}"
      end

      def read_yml(path)
        file_content = self.class.fetch(join_url(template_path, path))
        file_content ? YAML.load(file_content) : {}
      end

      ##
      # Download remote assets to a temporary directory
      # @return absolute path to the downloaded asset
      def locate_asset(asset)
        return nil unless asset

        destination = File.join(tmp_dir, asset["id"])
        return destination if File.exist?(destination)

        # Stream the response to the file (handle large files)
        File.open(destination, "wb") do |file|
          self.class.fetch(join_url(template_path, "assets", asset["id"])) do |chunk|
            file.write(chunk)
          end
        end
        destination
      end

      # Fetch the content of a remote file
      # Will follow redirects.
      # If no block given, load the whole response into memory.
      # If block given, stream the response to the block.
      # @param uri_str [String] The url to fetch
      # @param limit [Integer] The number of redirects to follow before raising an error
      # @return [String] The content of the remote file if no block given, otherwise nil
      def self.fetch(uri_str, limit = 3, &block)
        raise ArgumentError, "too many HTTP redirects" if limit.zero?

        uri = URI.parse(uri_str)
        body_response = nil
        Net::HTTP.get_response(uri) do |response|
          response_code = response.code.to_i
          if response_code >= 400
            nil
          elsif response_code >= 300
            location = redirect_location(response)
            next nil unless location

            body_response = fetch(location, limit - 1, &block)
          elsif block_given?
            response.read_body(&block)
          else
            body_response = response.body
          end
        end
        body_response
      rescue Addressable::URI::InvalidURIError, ArgumentError => e
        raise e
      rescue StandardError => e
        Rails.logger.error("Error fetching #{uri_str}: #{e.message}")
        nil
      end

      def self.redirect_location(response)
        location = response["location"].to_s.strip
        return nil if location.blank?

        uri = response.uri
        location_uri = if location.start_with?("/")
                         URI.parse("#{uri.scheme}://#{uri.host}#{uri.port ? ":#{uri.port}" : ""}#{location}")
                       else
                         URI.parse(location)
                       end

        location_uri.to_s
      end

      private

      def tmp_dir
        @tmp_dir ||= Dir.mktmpdir
      end

      def join_url(*paths)
        paths.map do |path|
          (path.start_with?("/") ? path.delete_prefix("/") : path).chomp("/")
        end.join("/")
      end
    end
  end
end
