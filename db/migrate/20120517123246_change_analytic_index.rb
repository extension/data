class ChangeAnalyticIndex < ActiveRecord::Migration
  def up
    remove_index("analytics", :name => "analytic_ndx")
    add_index "analytics", ["segment", "date", "page_id"], :name => "analytic_ndx"
  end

  def down
    remove_index("analytics", :name => "analytic_ndx")
    add_index "analytics", ["segment", "date"], :name => "analytic_ndx"
  end
end
