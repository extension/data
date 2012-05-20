class AddWeekStat < ActiveRecord::Migration
  def change
    create_table "week_stats", :force => true do |t|
      t.integer  "statable_id"
      t.string  "statable_type"
      t.integer  "year",                             :default => 0
      t.integer  "week",                             :default => 0
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "entrances"
      t.integer  "time_on_page"
      t.integer  "exits"
      t.timestamps
    end

    add_index "week_stats", ["statable_id","statable_type","year","week"], :name => "recordsignature", :unique => true

  end

end
