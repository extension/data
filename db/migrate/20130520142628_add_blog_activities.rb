class AddBlogActivities < ActiveRecord::Migration
  def change

    create_table "blogs_activities", :force => true do |t|
      t.integer  "person_id"
      t.integer  "blog_id"
      t.integer  "blog_name"
      t.integer  "post_id"
      t.integer  "item_id"
      t.string   "compound_post_id"
      t.string   "activity_category", :limit => 25
      t.datetime "created_at"
    end

    add_index "blogs_activities", ["person_id", "compound_post_id", "activity_category", "created_at"], :name => "person_activity_ndx"

  end
end
