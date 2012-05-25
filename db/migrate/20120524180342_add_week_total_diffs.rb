class AddWeekTotalDiffs < ActiveRecord::Migration
  def change
    create_table "total_diffs", :force => true do |t|
      t.integer  "resource_tag_id"
      t.string   "datatype",                        :null => false
      t.integer  "year",             :default => 0
      t.integer  "week",             :default => 0
      t.date     "yearweek_date"
      t.integer  "previous_pages",    :default => 0
      t.integer  "current_pages",    :default => 0
      t.integer  "previous_upv"
      t.integer  "current_upv"
      t.float    "pct_upv_difference"
      t.float    "pct_upv_change"
      t.float    "previous_avg_upv"
      t.float    "current_avg_upv"
      t.float    "pct_avg_upv_difference"
      t.float    "pct_avg_upv_change"
      t.timestamps
    end

    add_index "total_diffs", ["resource_tag_id","datatype","year","week"], :name => "recordsignature", :unique => true
  end
end
