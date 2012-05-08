class CreateRawAnalytics < ActiveRecord::Migration
  def change
    create_table  "raw_analytics", :force => true do |t|
      t.string   "segment",            :limit => 25
      t.date     "date"
      t.text     "analytics_url"
      t.string   "analytics_url_hash"
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "entrances"
      t.integer  "time_on_page"
      t.integer  "exits"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    add_index "raw_analytics", ["analytics_url_hash"], :name => "recordsignature", :unique => true
    add_index "raw_analytics", ["segment", "date"], :name => "analytic_ndx"
    
  end

end
