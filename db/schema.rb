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

ActiveRecord::Schema.define(:version => 20120507205014) do

  create_table "raw_analytics", :force => true do |t|
    t.string   "segment",            :limit => 25
    t.date     "date"
    t.text     "analytics_url"
    t.string   "analytics_url_hash"
    t.integer  "pageviews"
    t.integer  "unique_pageviews"
    t.integer  "entrances"
    t.integer  "time_on_page"
    t.integer  "exits"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "raw_analytics", ["analytics_url_hash"], :name => "recordsignature", :unique => true
  add_index "raw_analytics", ["segment", "date"], :name => "analytic_ndx"

end
