class AddLocationsCounties < ActiveRecord::Migration
  def change

    create_table "counties", :force => true do |t|
      t.integer "fipsid",                    :default => 0,  :null => false
      t.integer "location_id",               :default => 0,  :null => false
      t.integer "state_fipsid",              :default => 0,  :null => false
      t.string  "countycode",   :limit => 3, :default => "", :null => false
      t.string  "name",                      :default => "", :null => false
      t.string  "censusclass",  :limit => 2, :default => "", :null => false
    end

    add_index "counties", ["fipsid"], :name => "fipsid_ndx", :unique => true
    add_index "counties", ["location_id"], :name => "location_ndx"
    add_index "counties", ["name"], :name => "name_ndx"
    add_index "counties", ["state_fipsid"], :name => "state_fipsid_ndx"

    create_table "locations", :force => true do |t|
      t.integer "fipsid",                     :default => 0,  :null => false
      t.integer "entrytype",                  :default => 0,  :null => false
      t.string  "name",                       :default => "", :null => false
      t.string  "abbreviation", :limit => 10, :default => "", :null => false
      t.string  "office_link"
    end

    add_index "locations", ["fipsid"], :name => "fipsid_ndx", :unique => true
    add_index "locations", ["name"], :name => "name_ndx", :unique => true


    county_query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{County.table_name} SELECT * FROM prod_darmok.counties WHERE prod_darmok.counties.name != 'all'
    END_SQL
    execute(county_query)

    location_query = <<-END_SQL.gsub(/\s+/, " ").strip
      INSERT INTO #{Location.table_name} SELECT * FROM prod_darmok.locations
    END_SQL
    execute(location_query)

  end

end
