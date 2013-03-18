class AddAaeQuestionSummary < ActiveRecord::Migration
  def change

    create_table "questions", :force => true do |t|
      t.integer :detected_location_id
      t.integer :detected_county_id
      t.integer :location_id
      t.integer :county_id
      t.integer :detected_county_id
      t.integer :original_group_id
      t.string  :original_group_name
      t.integer :assigned_group_id
      t.string  :assigned_group_name
      t.string  :status
      t.boolean :submitted_from_mobile
      t.datetime :submitted_at
      t.integer :submitter_id
      t.boolean :submitter_is_extension
      t.integer :aae_version
      t.string  :source
      t.integer :comment_count
      t.integer :submitter_response_count
      t.integer :expert_response_count
      t.integer :expert_responders
      t.datetime :initial_response_at
      t.integer :initial_responder_id
      t.float :initial_response_time
      t.float :mean_response_time
      t.float :median_response_time
      t.text  :tags
    end

    add_index "questions", ["initial_responder_id"], :name => 'contributor_ndx'
    add_index "questions", ["submitted_at","initial_response_at"], :name => 'datetime_ndx'
    add_index "questions", ["source","aae_version","status"], :name => "filter_ndx"
    add_index "questions", ["detected_location_id","detected_county_id","location_id","county_id"], :name => "location_ndx"

  end
end
