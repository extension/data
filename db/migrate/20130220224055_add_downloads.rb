class AddDownloads < ActiveRecord::Migration
  def change

    create_table "downloads", :force => true do |t|
      t.string   "label"
      t.string   "filetype"
      t.string   "objectclass"
      t.string   "objectmethod"             
      t.integer  "period", :default => 0
      t.datetime "last_generated_at"
      t.float    "last_runtime"
      t.integer  "last_filesize"
      t.timestamps
    end

    add_index "downloads", ["label","period"], :name => "download_ndx"

    # create initial downloads
    Download.reset_column_information
    Download.create(label: 'evaluation', objectclass: 'AaeQuestion', objectmethod: 'evaluation_data_csv', filetype: 'csv', period: Download::DAILY )
  end

end
