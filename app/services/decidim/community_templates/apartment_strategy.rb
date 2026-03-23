# frozen_string_literal: true

module Decidim
  module CommunityTemplates
    class ApartmentStrategy
      def self.for(compatible: Decidim::CommunityTemplates.apartment_compat?)
        compatible ? MultiTenantStrategy.new : SingleTenantStrategy.new
      end
    end

    class MultiTenantStrategy
      def each_tenant(&block)
        Decidim::Apartment::DistributionKey.all.each do |distribution_key|
          distribution_key.switch(&block)
        end
      end
    end

    class SingleTenantStrategy
      def each_tenant
        yield
      end
    end
  end
end
