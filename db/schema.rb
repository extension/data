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

ActiveRecord::Schema.define(:version => 20130523015246) do

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
    t.integer  "tag_id"
  end

  add_index "analytics", ["analytics_url_hash"], :name => "recordsignature", :unique => true
  add_index "analytics", ["tag_id"], :name => "tag_id_ndx"
  add_index "analytics", ["year", "week", "page_id"], :name => "analytic_ndx"

  create_table "collected_page_stats", :force => true do |t|
    t.integer  "statable_id"
    t.string   "statable_type",   :limit => 25, :null => false
    t.string   "datatype",        :limit => 25, :null => false
    t.string   "metric",          :limit => 25, :null => false
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
    t.datetime "created_at",                    :null => false
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

  create_table "downloads", :force => true do |t|
    t.string   "label"
    t.string   "display_label"
    t.string   "filetype"
    t.string   "objectclass"
    t.string   "objectmethod"
    t.boolean  "method_writes_file", :default => false
    t.integer  "period",             :default => 0
    t.boolean  "in_progress",        :default => false
    t.boolean  "is_private",         :default => false
    t.datetime "last_generated_at"
    t.float    "last_runtime"
    t.integer  "last_filesize"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  add_index "downloads", ["label", "period"], :name => "download_ndx"

  create_table "geo_names", :force => true do |t|
    t.string  "feature_name",       :limit => 121
    t.string  "feature_class",      :limit => 51
    t.string  "state_abbreviation", :limit => 3
    t.string  "state_code",         :limit => 3
    t.string  "county",             :limit => 101
    t.string  "county_code",        :limit => 4
    t.string  "lat_dms",            :limit => 8
    t.string  "long_dms",           :limit => 9
    t.float   "lat"
    t.float   "long"
    t.string  "source_lat_dms",     :limit => 8
    t.string  "source_long_dms",    :limit => 9
    t.float   "source_lat"
    t.float   "source_long"
    t.integer "elevation"
    t.string  "map_name"
    t.string  "create_date_txt"
    t.string  "edit_date_txt"
    t.date    "create_date"
    t.date    "edit_date"
  end

  add_index "geo_names", ["feature_name", "state_abbreviation", "county"], :name => "name_state_county_ndx"

  create_table "groups", :force => true do |t|
    t.integer  "create_gid"
    t.string   "name"
    t.boolean  "is_launched"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.boolean  "publishing_community", :default => false
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

  create_table "locations", :force => true do |t|
    t.integer "fipsid",                     :default => 0,  :null => false
    t.integer "entrytype",                  :default => 0,  :null => false
    t.string  "name",                       :default => "", :null => false
    t.string  "abbreviation", :limit => 10, :default => "", :null => false
    t.string  "office_link"
  end

  add_index "locations", ["fipsid"], :name => "fipsid_ndx", :unique => true
  add_index "locations", ["name"], :name => "name_ndx", :unique => true

  create_table "node_activities", :force => true do |t|
    t.integer  "node_id"
    t.integer  "contributor_id"
    t.integer  "node_revision_id"
    t.integer  "event"
    t.string   "activity",         :limit => 25
    t.text     "log"
    t.datetime "created_at"
  end

  add_index "node_activities", ["contributor_id", "event", "activity", "created_at"], :name => "contributor_activity_ndx"
  add_index "node_activities", ["event", "activity", "created_at"], :name => "event_activity_ndx"
  add_index "node_activities", ["node_id", "event", "activity", "created_at"], :name => "node_activity_ndx"
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

  create_table "node_totals", :force => true do |t|
    t.integer  "node_id"
    t.string   "activity",                   :limit => 25, :null => false
    t.float    "total_weeks"
    t.integer  "contributed_weeks"
    t.integer  "contributions"
    t.integer  "contributors"
    t.float    "mean_weekly_contributions"
    t.float    "mean_weekly_contributors"
    t.integer  "yearweek"
    t.integer  "contributions_this_week"
    t.integer  "contributors_this_week"
    t.integer  "max_weekly_contributions"
    t.integer  "max_yearweek_contributions"
    t.integer  "max_weekly_contributors"
    t.integer  "max_yearweek_contributors"
    t.datetime "created_at",                               :null => false
  end

  add_index "node_totals", ["node_id", "activity"], :name => "node_activity_ndx", :unique => true

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

  create_table "page_totals", :force => true do |t|
    t.integer  "page_id"
    t.string   "metric",          :limit => 25, :null => false
    t.float    "total_weeks"
    t.float    "total"
    t.float    "seen_weeks"
    t.float    "mean"
    t.integer  "yearweek"
    t.float    "this_week"
    t.float    "previous_week"
    t.float    "previous_year"
    t.float    "pct_change_week"
    t.float    "pct_change_year"
    t.float    "max"
    t.integer  "max_yearweek"
    t.datetime "created_at",                    :null => false
  end

  add_index "page_totals", ["page_id", "metric"], :name => "page_ndx", :unique => true

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

  create_table "question_activities", :force => true do |t|
    t.integer  "contributor_id"
    t.integer  "question_id"
    t.integer  "activity"
    t.string   "activity_text"
    t.datetime "activity_at"
  end

  add_index "question_activities", ["activity_at"], :name => "datetime_ndx"
  add_index "question_activities", ["contributor_id", "activity"], :name => "contributor_activity_ndx"
  add_index "question_activities", ["question_id"], :name => "question_ndx"

  create_table "question_assignments", :force => true do |t|
    t.integer  "contributor_id"
    t.integer  "question_id"
    t.integer  "assigned_by"
    t.datetime "assigned_at"
    t.integer  "time_since_submitted_at"
    t.integer  "time_assigned"
    t.string   "next_handled_result"
    t.integer  "next_handled_by"
    t.datetime "next_handled_at"
    t.integer  "next_handled_id"
    t.boolean  "handled_by_assignee"
  end

  add_index "question_assignments", ["assigned_at"], :name => "datetime_ndx"
  add_index "question_assignments", ["contributor_id", "assigned_by", "next_handled_by"], :name => "people_nex"
  add_index "question_assignments", ["question_id"], :name => "question_ndx"

  create_table "questions", :force => true do |t|
    t.integer  "detected_location_id"
    t.integer  "detected_county_id"
    t.integer  "location_id"
    t.integer  "county_id"
    t.integer  "original_group_id"
    t.string   "original_group_name"
    t.integer  "assigned_group_id"
    t.string   "assigned_group_name"
    t.string   "status"
    t.boolean  "submitted_from_mobile"
    t.datetime "submitted_at"
    t.integer  "submitter_id"
    t.boolean  "submitter_is_extension"
    t.integer  "aae_version"
    t.string   "source"
    t.integer  "comment_count"
    t.integer  "submitter_response_count"
    t.integer  "expert_response_count"
    t.integer  "expert_responders"
    t.datetime "initial_response_at"
    t.integer  "initial_responder_id"
    t.float    "initial_response_time"
    t.float    "mean_response_time"
    t.float    "median_response_time"
    t.text     "tags"
    t.string   "ip_address"
    t.integer  "original_location_id"
    t.integer  "original_county_id"
  end

  add_index "questions", ["detected_location_id", "detected_county_id", "location_id", "county_id"], :name => "location_ndx"
  add_index "questions", ["initial_responder_id"], :name => "contributor_ndx"
  add_index "questions", ["source", "aae_version", "status"], :name => "filter_ndx"
  add_index "questions", ["submitted_at", "initial_response_at"], :name => "datetime_ndx"

  create_table "rebuilds", :force => true do |t|
    t.string   "group"
    t.string   "single_model"
    t.string   "single_action"
    t.boolean  "in_progress"
    t.datetime "started"
    t.datetime "finished"
    t.float    "run_time"
    t.string   "current_model"
    t.string   "current_action"
    t.datetime "current_start"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rebuilds", ["created_at"], :name => "created_ndx"

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
    t.integer  "rebuild_id"
    t.string   "item"
    t.string   "operation"
    t.float    "run_time"
    t.text     "additionaldata"
    t.datetime "created_at"
  end

  add_index "update_times", ["item"], :name => "item_ndx"

end
