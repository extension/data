class AddUpdateTimes < ActiveRecord::Migration
  def change
    create_table "update_times", :force => true do |t|
      t.string   "item"
      t.float    "run_time"
      t.text     "additionaldata" 
      t.datetime "created_at"
    end
    
    add_index "update_times", ["item"], :name => 'item_ndx'

  end

end
