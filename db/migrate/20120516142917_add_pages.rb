class AddPages < ActiveRecord::Migration
  
  def change
    
    # pages
    create_table "pages", :force => true do |t|
      t.integer  "migrated_id"
      t.string   "datatype"
      t.text     "title"
      t.string   "url_title",          :limit => 101
      t.integer  "content_length",                           :default => 0
      t.integer  "content_words",                           :default => 0
      t.datetime "source_created_at"
      t.datetime "source_updated_at"
      t.string   "source"
      t.text     "source_url"
      t.integer  "indexed",                           :default => 1
      t.boolean  "is_dpl",                            :default => false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "total_links"
      t.integer  "external_links"
      t.integer  "internal_links"
      t.integer  "local_links"
      t.text     "resource_tag_names"
    end

    add_index "pages", ["created_at", "datatype", "indexed"], :name => "page_type_ndx"
    add_index "pages", ["datatype"], :name => "index_pages_on_datatype"
    add_index "pages", ["migrated_id"], :name => "index_pages_on_migrated_id"
    add_index "pages", ["title"], :name => "index_pages_on_title", :length => {"title"=>255}
    
    create_table "page_taggings", :force => true do |t|
      t.integer  "page_id"
      t.integer  "resource_tag_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "page_taggings", ["page_id", "resource_tag_id"], :name => "pt_ndx"
    
    
    create_table "resource_tags", :force => true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "resource_tags", ["name"], :name => "rt_ndx"
        
  end
  
end

