class AddWorkflowEvents < ActiveRecord::Migration
  def change
    # groups
    create_table "workflow_events", :force => true do |t|
      t.integer  "node_id"
      t.integer  "workflow_state_id"
      t.integer  "user_id"
      t.integer  "node_revision_id"
      t.integer  "event"
      t.string   "event_description"
      t.datetime "created_at"
    end
    
    add_index "workflow_events", ["node_id"], :name => "node_ndx"
  
  
  end
end
