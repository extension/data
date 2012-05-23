class AddPagetypeToWeekTotals < ActiveRecord::Migration
  def up
    execute("TRUNCATE TABLE week_totals;")
    remove_index "week_totals", :name => "recordsignature"
    add_column "week_totals", "datatype", :string, :null => false
    add_index "week_totals", ["resource_tag_id","datatype","year","week"], :name => "recordsignature", :unique => true
  end
  
  def down
    remove_index "week_totals", :name => "recordsignature"
    remove_column "week_totals", "datatype"
    add_index "week_totals", ["resource_tag_id","year","week"], :name => "recordsignature", :unique => true
  end
end
