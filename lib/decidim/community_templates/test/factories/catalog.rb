# frozen_string_literal: true

FactoryBot.define do
  factory :catalog, class: "Decidim::CommunityTemplates::Catalog" do
    skip_create
    templates { [build(:template)] }
  end
end
