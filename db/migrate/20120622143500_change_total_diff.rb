class ChangeTotalDiff < ActiveRecord::Migration
  
  def up

    # having to drop and recreate again because of the integer/float - and it's just easier
    drop_table("total_diffs")
    
    create_table "total_diffs", :force => true do |t|
      t.integer  "group_id"
      t.string   "datatype",                              :null => false
      t.integer  "yearweek",                  :default => 0
      t.integer  "year",                      :default => 0
      t.integer  "week",                      :default => 0
      t.date     "yearweek_date"
      t.integer  "pages",                     :default => 0
      t.integer  "pages_previous_week",       :default => 0
      t.integer  "pages_previous_year",       :default => 0
      t.integer  "total_views",               :default => 0
      t.integer  "total_views_previous_week", :default => 0
      t.integer  "total_views_previous_year", :default => 0
      t.float    "views",                     :default => 0
      t.float    "views_previous_week",       :default => 0
      t.float    "views_previous_year",       :default => 0
      t.float    "pct_difference_week",       :default => 0
      t.float    "pct_difference_year",       :default => 0
      t.float    "pct_change_week",           :default => 0
      t.float    "pct_change_year",           :default => 0
      t.datetime "created_at",                :null => false
    end

    add_index "total_diffs", ["group_id", "datatype", "year", "week"], :name => "recordsignature", :unique => true
    

  end

end
