class AddReadabilityScores < ActiveRecord::Migration
  def change

    create_table "aae_readability_scores", :force => true do |t|
      t.integer  "aae_response_id"
      t.integer  "question_id"
      t.datetime "aae_response_at"
      t.boolean  "is_expert"
      t.float     "flesch"
      t.float     "fog"
      t.float     "kincaid"
      t.text      "frequencies",          :limit => 16777215
      t.text      "data"
    end

    create_table "page_readability_scores", :force => true do |t|
      t.integer  "page_id"
      t.float     "flesch"
      t.float     "fog"
      t.float     "kincaid"
      t.text      "frequencies",          :limit => 16777215
      t.text      "data"
    end

  end

end
