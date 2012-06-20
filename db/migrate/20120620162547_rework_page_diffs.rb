class ReworkPageDiffs < ActiveRecord::Migration
  def up
    drop_table('week_diffs')
    
    create_table "page_diffs", :force => true do |t|
      t.integer  "page_id"
      t.integer  "year",           :default => 0
      t.integer  "week",           :default => 0
      t.integer  "views"
      t.integer  "views_previous_week"
      t.integer  "views_previous_year"
      t.float    "pct_difference_week"
      t.float    "pct_difference_year"
      t.float    "pct_change_week"
      t.float    "pct_change_year"
      t.datetime "created_at",                    :null => false
    end

    add_index "page_diffs", ["page_id", "year", "week"], :name => "recordsignature", :unique => true
    
  end

  def down
  end
end
