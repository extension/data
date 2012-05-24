class AddWeekDiffs < ActiveRecord::Migration
  def change
    create_table "week_diffs", :force => true do |t|
      t.integer  "page_id"
      t.integer  "year",                             :default => 0
      t.integer  "week",                             :default => 0
      t.integer  "previous_upv"
      t.integer  "current_upv"
      t.float    "pct_difference"
      t.float    "pct_change"
      t.timestamps
    end

    add_index "week_diffs", ["page_id","year","week"], :name => "recordsignature", :unique => true

  end

end
