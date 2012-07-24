class AddNodeContributors < ActiveRecord::Migration
  def change
    
    create_table "node_metacontributions", :force => true do |t|
      t.integer  "node_id"
      t.integer  "user_id"
      t.integer  "node_revision_id"
      t.string   "role"
      t.string   "author"
      t.datetime "contributed_at"
      t.datetime "created_at"
    end
    
    add_index "node_metacontributions", ["node_id"], :name => "node_ndx"
    add_index "node_metacontributions", ["user_id"], :name => "user_ndx"
    
  end
  
end
