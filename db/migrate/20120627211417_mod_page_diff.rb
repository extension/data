class ModPageDiff < ActiveRecord::Migration
  def change
    drop_table("page_diffs")
    
    create_table "page_diffs", :force => true do |t|
      t.integer  "page_id"
      t.integer  "yearweek",              :default => 0
      t.integer  "year",                  :default => 0
      t.integer  "week",                  :default => 0
      t.integer  "views"
      t.integer  "views_previous_week"
      t.integer  "views_previous_year"
      t.float    "pct_difference_week"
      t.float    "pct_difference_year"
      t.float    "recent_pct_difference"
      t.float    "pct_change_week"
      t.float    "pct_change_year"
      t.float    "recent_pct_change"
      t.datetime "created_at",                           :null => false
    end
    
    add_index "page_diffs", ["page_id", "year", "week"], :name => "recordsignature", :unique => true
 
  end
end
