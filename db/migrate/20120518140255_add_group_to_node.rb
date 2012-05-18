class AddGroupToNode < ActiveRecord::Migration
  def change
      # groups
      create_table "node_groups", :force => true do |t|
        t.integer  "node_id"
        t.integer  "group_id"
        t.datetime "created_at"
      end
    
      add_index "node_groups", ["node_id","group_id"], :name => "create_group_ndx"
  
  
  end
end
