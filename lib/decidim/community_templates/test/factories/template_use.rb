# frozen_string_literal: true

FactoryBot.define do
  factory :community_template_use, class: "Decidim::CommunityTemplates::TemplateUse" do
    organization { create(:organization) }
    resource { create(:participatory_process, organization: organization || create(:organization)) }
    template_id { SecureRandom.uuid }
  end
end
