class ResetTables < ActiveRecord::Migration
  def change

    create_table "aae_nodes", :force => true do |t|
      t.integer "node_id"
      t.integer "aae_id"
    end

    add_index "aae_nodes", ["node_id", "aae_id"], :name => "node_group_ndx"

    create_table "collected_page_stats", :force => true do |t|
      t.integer  "statable_id"
      t.string   "statable_type", limit: 25, null: false
      t.string   "datatype", limit: 25, null: false
      t.string   "metric", limit: 25, null: false
      t.integer  "yearweek"
      t.integer  "year"
      t.integer  "week"
      t.date     "yearweek_date"
      t.integer  "pages"
      t.integer  "seen"
      t.float    "total"
      t.float    "per_page"
      t.float    "previous_week"
      t.float    "previous_year"
      t.float    "pct_change_week"
      t.float    "pct_change_year"
      t.float    "pct_99"
      t.float    "pct_95"
      t.float    "pct_90"
      t.float    "pct_75"
      t.float    "pct_50"
      t.float    "pct_25"
      t.float    "pct_10"
      t.datetime "created_at", null: false
    end

    add_index "collected_page_stats", ["statable_id", "statable_type", "datatype", "metric", "yearweek", "year", "week"], :name => "recordsignature", :unique => true


    create_table "contributor_groups", :force => true do |t|
      t.integer  "contributor_id"
      t.integer  "group_id"
      t.datetime "created_at"
    end

    add_index "contributor_groups", ["group_id", "contributor_id"], :name => "connection_ndx", :unique => true

    create_table "contributors", :force => true do |t|
      t.string   "idstring",           :limit => 80,                    :null => false
      t.string   "openid_uid"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "email",              :limit => 96
      t.string   "title"
      t.integer  "account_status"
      t.datetime "last_login_at"
      t.integer  "position_id"
      t.integer  "location_id"
      t.integer  "county_id"
      t.boolean  "retired",                          :default => false
      t.boolean  "is_admin",                         :default => false
      t.integer  "primary_account_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "contributors", ["openid_uid"], :name => "openid_ndx"

    create_table "delayed_jobs", :force => true do |t|
      t.integer  "priority"
      t.integer  "attempts"
      t.text     "handler"
      t.text     "last_error"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by"
      t.string   "queue"
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
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

    create_table "landing_stats", :force => true do |t|
      t.integer  "group_id"
      t.integer  "yearweek"
      t.integer  "year"
      t.integer  "week"
      t.date     "yearweek_date"
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "entrances"
      t.integer  "time_on_page"
      t.integer  "exits"
      t.integer  "visitors"
      t.integer  "new_visits"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    add_index "landing_stats", ["group_id", "yearweek", "year", "week"], :name => "recordsignature", :unique => true

    create_table "node_activities", :force => true do |t|
      t.integer  "node_id"
      t.integer  "contributor_id"
      t.integer  "node_revision_id"
      t.integer  "event"
      t.string  "activity", :limit => 25
      t.text     "log"
      t.datetime "created_at"
    end

    add_index "node_activities", ["contributor_id", "event", "activity", "created_at"], :name => "contributor_activity_ndx"
    add_index "node_activities", ["event", "activity", "created_at"], :name => "event_activity_ndx"
    add_index "node_activities", ["node_id", "event", "activity","created_at"], :name => "node_activity_ndx"
    add_index "node_activities", ["node_id"], :name => "node_ndx"

    create_table "node_groups", :force => true do |t|
      t.integer  "node_id"
      t.integer  "group_id"
      t.datetime "created_at"
    end

    add_index "node_groups", ["node_id", "group_id"], :name => "create_group_ndx"

    create_table "node_metacontributions", :force => true do |t|
      t.integer  "node_id"
      t.integer  "contributor_id"
      t.integer  "node_revision_id"
      t.string   "role"
      t.string   "author"
      t.datetime "contributed_at"
      t.datetime "created_at"
    end

    add_index "node_metacontributions", ["contributor_id"], :name => "contributor_ndx"
    add_index "node_metacontributions", ["node_id"], :name => "node_ndx"

    create_table "nodes", :force => true do |t|
      t.integer  "revision_id"
      t.string   "node_type"
      t.string   "title"
      t.boolean  "has_page",    :default => false
      t.datetime "created_at",                     :null => false
      t.datetime "updated_at",                     :null => false
    end

    add_index "nodes", ["has_page"], :name => "page_flag_ndx"
    add_index "nodes", ["node_type"], :name => "node_type_ndx"


    create_table "page_stats", :force => true do |t|
      t.integer  "page_id"
      t.integer  "yearweek"
      t.integer  "year"
      t.integer  "week"
      t.date     "yearweek_date"
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "entrances"
      t.integer  "time_on_page"
      t.integer  "exits"
      t.integer  "visitors"
      t.integer  "new_visits"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    add_index "page_stats", ["page_id", "yearweek", "year", "week"], :name => "recordsignature", :unique => true

    create_table "page_taggings", :force => true do |t|
      t.integer  "page_id"
      t.integer  "tag_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "page_taggings", ["page_id", "tag_id"], :name => "pt_ndx"

    create_table "pages", :force => true do |t|
      t.integer  "migrated_id"
      t.string   "datatype"
      t.text     "title"
      t.string   "url_title",         :limit => 101
      t.integer  "content_length"
      t.integer  "content_words"
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

    create_table "revisions", :force => true do |t|
      t.integer  "node_id"
      t.integer  "contributor_id"
      t.text     "log"
      t.datetime "created_at"
    end

    add_index "revisions", ["contributor_id"], :name => "contributor_ndx"
    add_index "revisions", ["node_id"], :name => "node_ndx"

    create_table "tags", :force => true do |t|
      t.string   "name",       :null => false
      t.integer  "group_id"
      t.datetime "created_at"
    end

    add_index "tags", ["group_id"], :name => "group_ndx"
    add_index "tags", ["name"], :name => "name_idx", :unique => true


    create_table "update_times", :force => true do |t|
      t.string   "item"
      t.string   "operation"
      t.float    "run_time"
      t.text     "additionaldata"
      t.datetime "created_at"
    end

    add_index "update_times", ["item"], :name => "item_ndx"


  end
end
