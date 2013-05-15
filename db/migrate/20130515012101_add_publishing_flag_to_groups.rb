class AddPublishingFlagToGroups < ActiveRecord::Migration
  def change
    add_column(:groups, 'publishing_community', :boolean, default: false)
  end
end
