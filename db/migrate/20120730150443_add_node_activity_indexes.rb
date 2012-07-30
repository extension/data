class AddNodeActivityIndexes < ActiveRecord::Migration
  def change
    add_index "nodes", ["node_type"], :name => "node_type_ndx"
    add_index "node_events", ["event","created_at"], :name => "event_activity_ndx"
    add_index "node_events", ["user_id","event","created_at"], :name => "user_activity_ndx"
    add_index "node_events", ["node_id","event","created_at"], :name => "node_activity_ndx"
  end
end
