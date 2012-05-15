class CreateAnalytics < ActiveRecord::Migration
  def change
    create_table "analytics", :force => true do |t|
      t.integer  "page_id"
      t.string   "segment",            :limit => 25
      t.date     "date"
      t.text     "analytics_url"
      t.string   "url_type"
      t.integer  "url_page_id"
      t.integer  "url_migrated_id"
      t.string   "url_wiki_title"
      t.string   "url_widget_id"
      t.string   "analytics_url_hash"
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "entrances"
      t.integer  "time_on_page"
      t.integer  "exits"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "analytics", ["analytics_url_hash"], :name => "recordsignature", :unique => true
    add_index "analytics", ["segment", "date"], :name => "analytic_ndx"

  end

end
