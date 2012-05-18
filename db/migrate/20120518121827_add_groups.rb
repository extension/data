class AddGroups < ActiveRecord::Migration
  def change
    # groups
    create_table "groups", :force => true do |t|
      t.integer  "create_gid"
      t.string   "name"
      t.boolean  "is_launched"
      t.timestamps
    end
    
    add_index "groups", ["create_gid"], :name => "create_group_ndx"
      
  end
end
