# frozen_string_literal: true

FactoryBot.define do
  factory :catalog, class: "Decidim::CommunityTemplates::Catalog" do
    skip_create
    templates { [build(:template_metadata, organization:)] }

    initialize_with do
      Decidim::CommunityTemplates::Catalog.from_path(Decidim::CommunityTemplates.catalog_path)
    end
  end
end
