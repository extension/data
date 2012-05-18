class AddUsers < ActiveRecord::Migration
  def change
    
    create_table "users", :force => true do |t|
      t.string   "idstring",                    :limit => 80,                    :null => false
      t.string   "first_name"
      t.string   "last_name"
      t.string   "email",                    :limit => 96
      t.string   "title"
      t.integer  "account_status"
      t.datetime "last_login_at"
      t.integer  "position_id",                            :default => 0
      t.integer  "location_id",                            :default => 0
      t.integer  "county_id",                              :default => 0
      t.boolean  "retired",                                :default => false
      t.boolean  "is_admin",                               :default => false
      t.integer  "primary_account_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
  end
end
