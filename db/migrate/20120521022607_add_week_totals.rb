class AddWeekTotals < ActiveRecord::Migration
  def change
    create_table "week_totals", :force => true do |t|
      t.integer  "resource_tag_id"
      t.integer  "year",                             :default => 0
      t.integer  "week",                             :default => 0
      t.integer  "pages",                            :default => 0
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "entrances"
      t.integer  "time_on_page"
      t.integer  "exits"
      t.timestamps
    end

    add_index "week_totals", ["resource_tag_id","year","week"], :name => "recordsignature", :unique => true

  end

end
