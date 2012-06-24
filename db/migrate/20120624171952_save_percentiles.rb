class SavePercentiles < ActiveRecord::Migration

  def change
    create_table "percentiles", :force => true do |t|
      t.integer  "group_id"
      t.string   "datatype",                                   :null => false
      t.integer  "yearweek",                  :default => 0
      t.integer  "year",                      :default => 0
      t.integer  "week",                      :default => 0
      t.integer  "total", :default => 0
      t.integer  "seen", :default => 0
      t.integer  "pct_99", :default => 0
      t.integer  "pct_95", :default => 0
      t.integer  "pct_90", :default => 0
      t.integer  "pct_75", :default => 0
      t.integer  "pct_50", :default => 0
      t.integer  "pct_25", :default => 0
      t.integer  "pct_10", :default => 0
      t.datetime "created_at",                                 :null => false
    end

    add_index "percentiles", ["group_id", "datatype", "yearweek"], :name => "recordsignature", :unique => true

  end

end
