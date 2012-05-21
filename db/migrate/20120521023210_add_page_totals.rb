class AddPageTotals < ActiveRecord::Migration
  def change
    create_table "page_totals", :force => true do |t|
      t.integer  "page_id"
      t.integer  "eligible_weeks",             :default => 0
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "entrances"
      t.integer  "time_on_page"
      t.integer  "exits"
      t.timestamps
    end

    add_index "page_totals", ["page_id"], :name => "page_ndx", :unique => true

  end

end
