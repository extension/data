class ReworkTotalDiffs < ActiveRecord::Migration
  def up
    drop_table("total_diffs")
    
    create_table "total_diffs", :force => true do |t|
      t.integer  "tag_id"
      t.string   "datatype",                              :null => false
      t.integer  "year",                      :default => 0
      t.integer  "week",                      :default => 0
      t.date     "yearweek_date"
      t.integer  "pages",                     :default => 0
      t.integer  "pages_previous_week",       :default => 0
      t.integer  "pages_previous_year",       :default => 0
      t.integer  "total_views",               :default => 0
      t.integer  "total_views_previous_week", :default => 0
      t.integer  "total_views_previous_year", :default => 0
      t.integer  "views",                     :default => 0
      t.integer  "views_previous_week",       :default => 0
      t.integer  "views_previous_year",       :default => 0
      t.float    "pct_difference_week",       :default => 0
      t.float    "pct_difference_year",       :default => 0
      t.float    "pct_change_week",           :default => 0
      t.float    "pct_change_year",           :default => 0
      t.datetime "created_at",                :null => false
    end

    add_index "total_diffs", ["tag_id", "datatype", "year", "week"], :name => "recordsignature", :unique => true
    
  end

  def down
  end
end
