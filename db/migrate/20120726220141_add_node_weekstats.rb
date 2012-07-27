class AddNodeWeekstats < ActiveRecord::Migration
  def change
  	create_table "node_week_totals", :force => true do |t|
      t.integer  "group_id"
      t.string   "datatype", :limit => 25
      t.string   "event_type", :limit => 25
      t.integer  "yearweek"
      t.integer  "year"
      t.integer  "week"
      t.date     "yearweek_date"
      t.integer  "eligible"
      t.integer  "total"
      t.integer  "items"
      t.integer  "users"
      t.datetime "created_at",                      :null => false
    end

    add_index "node_week_totals", ["group_id", "datatype", "event_type", "yearweek","year", "week"], :name => "recordsignature", :unique => true

  end
end
