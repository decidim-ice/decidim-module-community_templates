# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class FileLock
      def initialize(lock_path)
        @lock_path = lock_path
      end

      def with_lock
        File.open(@lock_path, "w") do |lock_file|
          if lock_file.flock(File::LOCK_EX | File::LOCK_NB)
            begin
              yield true
            ensure
              lock_file.flock(File::LOCK_UN)
            end
          else
            yield false
          end
        end
      end
    end
  end
end

