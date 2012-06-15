class AddTags < ActiveRecord::Migration
  def change
    create_table "tags", :force => true do |t|
      t.string   "name", :null => false
      t.integer  "group_id", :default => 0
      t.datetime "created_at"
    end
    
    add_index "tags", ["name"], :name => 'name_idx', :unique => true
    add_index "tags", ["group_id"], :name => 'group_ndx'
    
  end
end
