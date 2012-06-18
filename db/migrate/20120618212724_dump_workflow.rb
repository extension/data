class DumpWorkflow < ActiveRecord::Migration
  def up
    drop_table('workflow_events')
  end
end
