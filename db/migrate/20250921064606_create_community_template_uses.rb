# frozen_string_literal: true
class CreateCommunityTemplateUses < ActiveRecord::Migration[7.0]
  def change
    # TemplateUsage:
    # - template_id: the uuid of the template
    # - resource_id: the id of the resource using the template
    # - resource_type: the type of the resource using the template
    # - decidim_organization_id: the id of the organization using the template

    create_table :community_template_uses do |t|
      t.integer :decidim_organization_id,
                foreign_key: true,
                index: { name: "index_community_template_uses_on_decidim_organization_id" }
      t.integer :resource_id
      t.string :resource_type
      t.string :template_id, index: true

      t.index [:resource_type, :resource_id, :decidim_organization_id], name: "unique_community_template_uses_on_organization", unique: true

      t.timestamps
    end
  end
end
