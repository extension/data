class AddNodeActivityDiffs < ActiveRecord::Migration

    create_table "node_activity_diffs", :force => true do |t|
      t.integer  "group_id"
      t.string   "node_scope", :limit => 50
      t.string   "activity_scope", :limit => 25
      t.string   "metric",   :limit => 25
      t.integer  "yearweek"
      t.integer  "year"
      t.integer  "week"
      t.date     "yearweek_date"
      t.float    "metric_value"
      t.float    "previous_week"
      t.float    "previous_year"
      t.float    "pct_difference_week"
      t.float    "pct_difference_year"
      t.float    "recent_pct_difference"
      t.float    "pct_change_week"
      t.float    "pct_change_year"
      t.float    "recent_pct_change"
      t.datetime "created_at",                               :null => false
    end

    add_index "node_activity_diffs", ["group_id", "node_scope", "metric", "activity_scope", "yearweek","year", "week"], :name => "recordsignature", :unique => true


end
