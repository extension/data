class AddRevisions < ActiveRecord::Migration
  def change

    # nodes
    create_table "revisions", :force => true do |t|
      t.integer  "node_id"
      t.integer  "user_id"
      t.text     "log"
      t.datetime "created_at"
    end    

    add_index "revisions", ["node_id"], :name => "node_ndx"
    add_index "revisions", ["user_id"], :name => "user_ndx"
    
  end

end
