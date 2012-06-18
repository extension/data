class AddNodeEvents < ActiveRecord::Migration
  def change

    create_table "node_events", :force => true do |t|
      t.integer  "node_id"
      t.integer  "user_id"
      t.integer  "node_revision_id"
      t.integer  "event"
      t.text     "log"
      t.datetime "created_at"
    end

    add_index "node_events", ["node_id"], :name => "node_ndx"
    
  
  end
end
