class AddAaeQuestionAssignments < ActiveRecord::Migration
  def change
    create_table "question_assignments", :force => true do |t|
      t.integer  :contributor_id
      t.integer  :question_id
      t.integer  :assigned_by
      t.datetime :assigned_at
      t.integer  :time_since_submitted_at
      t.integer  :time_assigned
      t.string   :next_handled_result
      t.integer  :next_handled_by
      t.datetime :next_handled_at
      t.integer  :next_handled_id
      t.boolean  :handled_by_assignee
    end

    add_index "question_assignments", ["contributor_id","assigned_by","next_handled_by"], :name => 'people_nex'
    add_index "question_assignments", ["question_id"], :name => "question_ndx"
    add_index "question_assignments", ["assigned_at"], :name => "datetime_ndx"

  end
end
