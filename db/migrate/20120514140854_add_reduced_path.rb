class AddReducedPath < ActiveRecord::Migration
  def change
    add_column :raw_analytics, :reduced_path, :string
    add_index "raw_analytics", ["reduced_path"], :name => "path_ndx"
  end

end
