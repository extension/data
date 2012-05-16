# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120516142917) do

  create_table "analytics", :force => true do |t|
    t.integer  "page_id"
    t.string   "segment",            :limit => 25
    t.date     "date"
    t.text     "analytics_url"
    t.string   "url_type"
    t.integer  "url_page_id"
    t.integer  "url_migrated_id"
    t.string   "url_wiki_title"
    t.string   "url_widget_id"
    t.string   "analytics_url_hash"
    t.integer  "pageviews"
    t.integer  "unique_pageviews"
    t.integer  "entrances"
    t.integer  "time_on_page"
    t.integer  "exits"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "analytics", ["analytics_url_hash"], :name => "recordsignature", :unique => true
  add_index "analytics", ["segment", "date"], :name => "analytic_ndx"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "page_taggings", :force => true do |t|
    t.integer  "page_id"
    t.integer  "resource_tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "page_taggings", ["page_id", "resource_tag_id"], :name => "pt_ndx"

  create_table "pages", :force => true do |t|
    t.integer  "migrated_id"
    t.string   "datatype"
    t.text     "title"
    t.string   "url_title",          :limit => 101
    t.integer  "content_length",                    :default => 0
    t.integer  "content_words",                     :default => 0
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

  create_table "resource_tags", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_tags", ["name"], :name => "rt_ndx"

end
