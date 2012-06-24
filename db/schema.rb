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

ActiveRecord::Schema.define(:version => 20120624171952) do

  create_table "aae_nodes", :force => true do |t|
    t.integer "node_id"
    t.integer "aae_id"
  end

  add_index "aae_nodes", ["node_id", "aae_id"], :name => "node_group_ndx"

  create_table "analytics", :force => true do |t|
    t.integer  "page_id"
    t.integer  "yearweek"
    t.integer  "year"
    t.integer  "week"
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
    t.integer  "visitors"
    t.integer  "new_visits"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "analytics", ["analytics_url_hash"], :name => "recordsignature", :unique => true
  add_index "analytics", ["year", "week", "page_id"], :name => "analytic_ndx"

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

  create_table "groups", :force => true do |t|
    t.integer  "create_gid"
    t.string   "name"
    t.boolean  "is_launched"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "groups", ["create_gid"], :name => "create_group_ndx"

  create_table "node_events", :force => true do |t|
    t.integer  "node_id"
    t.integer  "user_id"
    t.integer  "node_revision_id"
    t.integer  "event"
    t.text     "log"
    t.datetime "created_at"
  end

  add_index "node_events", ["node_id"], :name => "node_ndx"

  create_table "node_groups", :force => true do |t|
    t.integer  "node_id"
    t.integer  "group_id"
    t.datetime "created_at"
  end

  add_index "node_groups", ["node_id", "group_id"], :name => "create_group_ndx"

  create_table "nodes", :force => true do |t|
    t.integer  "revision_id"
    t.string   "node_type"
    t.string   "title"
    t.boolean  "has_page",    :default => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "nodes", ["has_page"], :name => "page_flag_ndx"

  create_table "page_diffs", :force => true do |t|
    t.integer  "page_id"
    t.integer  "yearweek",            :default => 0
    t.integer  "year",                :default => 0
    t.integer  "week",                :default => 0
    t.integer  "views"
    t.integer  "views_previous_week"
    t.integer  "views_previous_year"
    t.float    "pct_difference_week"
    t.float    "pct_difference_year"
    t.float    "pct_change_week"
    t.float    "pct_change_year"
    t.datetime "created_at",                         :null => false
  end

  add_index "page_diffs", ["page_id", "year", "week"], :name => "recordsignature", :unique => true

  create_table "page_taggings", :force => true do |t|
    t.integer  "page_id"
    t.integer  "tag_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "page_taggings", ["page_id", "tag_id"], :name => "pt_ndx"

  create_table "page_totals", :force => true do |t|
    t.integer  "page_id"
    t.float    "eligible_weeks",   :default => 0.0
    t.integer  "pageviews"
    t.integer  "unique_pageviews"
    t.integer  "entrances"
    t.integer  "time_on_page"
    t.integer  "exits"
    t.integer  "visitors"
    t.integer  "new_visits"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "page_totals", ["page_id"], :name => "page_ndx", :unique => true

  create_table "pages", :force => true do |t|
    t.integer  "migrated_id"
    t.string   "datatype"
    t.text     "title"
    t.string   "url_title",         :limit => 101
    t.integer  "content_length",                   :default => 0
    t.integer  "content_words",                    :default => 0
    t.datetime "source_created_at"
    t.datetime "source_updated_at"
    t.string   "source"
    t.text     "source_url"
    t.integer  "indexed",                          :default => 1
    t.boolean  "is_dpl",                           :default => false
    t.integer  "total_links"
    t.integer  "external_links"
    t.integer  "internal_links"
    t.integer  "local_links"
    t.integer  "node_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pages", ["created_at", "datatype", "indexed"], :name => "page_type_ndx"
  add_index "pages", ["datatype"], :name => "index_pages_on_datatype"
  add_index "pages", ["migrated_id"], :name => "index_pages_on_migrated_id"
  add_index "pages", ["node_id"], :name => "node_ndx"
  add_index "pages", ["title"], :name => "index_pages_on_title", :length => {"title"=>255}

  create_table "percentiles", :force => true do |t|
    t.integer  "group_id"
    t.string   "datatype",                  :null => false
    t.integer  "yearweek",   :default => 0
    t.integer  "year",       :default => 0
    t.integer  "week",       :default => 0
    t.integer  "total",      :default => 0
    t.integer  "seen",       :default => 0
    t.integer  "pct_99",     :default => 0
    t.integer  "pct_95",     :default => 0
    t.integer  "pct_90",     :default => 0
    t.integer  "pct_75",     :default => 0
    t.integer  "pct_50",     :default => 0
    t.integer  "pct_25",     :default => 0
    t.integer  "pct_10",     :default => 0
    t.datetime "created_at",                :null => false
  end

  add_index "percentiles", ["group_id", "datatype", "yearweek"], :name => "recordsignature", :unique => true

  create_table "revisions", :force => true do |t|
    t.integer  "node_id"
    t.integer  "user_id"
    t.text     "log"
    t.datetime "created_at"
  end

  add_index "revisions", ["node_id"], :name => "node_ndx"
  add_index "revisions", ["user_id"], :name => "user_ndx"

  create_table "tags", :force => true do |t|
    t.string   "name",                      :null => false
    t.integer  "group_id",   :default => 0
    t.datetime "created_at"
  end

  add_index "tags", ["group_id"], :name => "group_ndx"
  add_index "tags", ["name"], :name => "name_idx", :unique => true

  create_table "total_diffs", :force => true do |t|
    t.integer  "group_id"
    t.string   "datatype",                                   :null => false
    t.integer  "yearweek",                  :default => 0
    t.integer  "year",                      :default => 0
    t.integer  "week",                      :default => 0
    t.date     "yearweek_date"
    t.integer  "pages",                     :default => 0
    t.integer  "pages_previous_week",       :default => 0
    t.integer  "pages_previous_year",       :default => 0
    t.integer  "total_views",               :default => 0
    t.integer  "total_views_previous_week", :default => 0
    t.integer  "total_views_previous_year", :default => 0
    t.float    "views",                     :default => 0.0
    t.float    "views_previous_week",       :default => 0.0
    t.float    "views_previous_year",       :default => 0.0
    t.float    "pct_difference_week",       :default => 0.0
    t.float    "pct_difference_year",       :default => 0.0
    t.float    "pct_change_week",           :default => 0.0
    t.float    "pct_change_year",           :default => 0.0
    t.datetime "created_at",                                 :null => false
  end

  add_index "total_diffs", ["group_id", "datatype", "year", "week"], :name => "recordsignature", :unique => true

  create_table "update_times", :force => true do |t|
    t.string   "item"
    t.string   "operation"
    t.float    "run_time"
    t.text     "additionaldata"
    t.datetime "created_at"
  end

  add_index "update_times", ["item"], :name => "item_ndx"

  create_table "users", :force => true do |t|
    t.string   "idstring",           :limit => 80,                    :null => false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email",              :limit => 96
    t.string   "title"
    t.integer  "account_status"
    t.datetime "last_login_at"
    t.integer  "position_id",                      :default => 0
    t.integer  "location_id",                      :default => 0
    t.integer  "county_id",                        :default => 0
    t.boolean  "retired",                          :default => false
    t.boolean  "is_admin",                         :default => false
    t.integer  "primary_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "week_stats", :force => true do |t|
    t.integer  "page_id"
    t.integer  "yearweek"
    t.integer  "year",             :default => 0
    t.integer  "week",             :default => 0
    t.integer  "pageviews"
    t.integer  "unique_pageviews"
    t.integer  "entrances"
    t.integer  "time_on_page"
    t.integer  "exits"
    t.integer  "visitors"
    t.integer  "new_visits"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "week_stats", ["page_id", "year", "week"], :name => "recordsignature", :unique => true

  create_table "week_totals", :force => true do |t|
    t.integer  "tag_id"
    t.string   "datatype",                        :null => false
    t.integer  "year",             :default => 0
    t.integer  "week",             :default => 0
    t.integer  "pages",            :default => 0
    t.integer  "pageviews"
    t.integer  "unique_pageviews"
    t.integer  "entrances"
    t.integer  "time_on_page"
    t.integer  "exits"
    t.integer  "visitors"
    t.integer  "new_visits"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "week_totals", ["tag_id", "datatype", "year", "week"], :name => "recordsignature", :unique => true

end
