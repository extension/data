class AddEventActivity < ActiveRecord::Migration
  def change

    create_table "event_activities", :force => true do |t|
      t.integer  "event_id"
      t.integer  "person_id"
      t.integer  "item_id"
      t.string   "activity_category", :limit => 25
      t.datetime "created_at"
    end

    add_index "event_activities", ["person_id", "event_id", "item_id", "activity_category", "created_at"], :name => "person_activity_ndx"

  end
end
