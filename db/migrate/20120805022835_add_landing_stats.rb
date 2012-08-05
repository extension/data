class AddLandingStats < ActiveRecord::Migration
  def change

    create_table "landing_stats", :force => true do |t|
      t.integer  "group_id"
      t.integer  "yearweek"
      t.integer  "year"
      t.integer  "week"
      t.date     "yearweek_date"
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "entrances"
      t.integer  "time_on_page"
      t.integer  "exits"
      t.integer  "visitors"
      t.integer  "new_visits"
      t.datetime "created_at",                      :null => false
      t.datetime "updated_at",                      :null => false
    end

    add_index "landing_stats", ["group_id", "yearweek","year", "week"], :name => "recordsignature", :unique => true

    create_table "landing_diffs", :force => true do |t|
      t.integer  "group_id"
      t.string   "metric"
      t.integer  "yearweek"
      t.integer  "year"
      t.integer  "week"
      t.date     "yearweek_date"
      t.float    "total"
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

    add_index "landing_diffs", ["group_id", "metric", "yearweek","year", "week"], :name => "recordsignature", :unique => true


  end
end
