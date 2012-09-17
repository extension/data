class CreateContributorGroups < ActiveRecord::Migration
  def change
    create_table "contributor_groups", :force => true do |t|
      t.references  :contributor
      t.references  :group
      t.datetime "created_at"
    end

    add_index "contributor_groups", ["group_id", "contributor_id"], :name => "connection_ndx", :unique => true
  end
end
