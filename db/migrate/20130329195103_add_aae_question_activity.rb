class AddAaeQuestionActivity < ActiveRecord::Migration
  def change
    create_table "question_activities", :force => true do |t|
      t.integer  :contributor_id
      t.integer  :question_id
      t.integer  :activity
      t.string   :activity_text
      t.datetime :activity_at
    end
 
    add_index "question_activities", ["contributor_id",'activity'], :name => 'contributor_activity_ndx'
    add_index "question_activities", ["question_id"], :name => "question_ndx"
    add_index "question_activities", ["activity_at"], :name => "datetime_ndx"

  end
end