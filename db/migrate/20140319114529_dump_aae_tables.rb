class DumpAaeTables < ActiveRecord::Migration
  def up
    drop_table('questions')
    drop_table('question_assignments')
    drop_table('question_activities')
  end
end
