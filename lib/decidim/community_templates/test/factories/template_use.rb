# frozen_string_literal: true

FactoryBot.define do
  factory :community_template_use, class: "Decidim::CommunityTemplates::TemplateUse" do
    organization { create(:organization, available_locales: ["en"]) }
    resource { create(:participatory_process, organization: organization || create(:organization, available_locales: ["en"])) }
    template_id { SecureRandom.uuid }
  end
end
