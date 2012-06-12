class AddPageFlagToNode < ActiveRecord::Migration
  def change
    add_column "nodes", "has_page", :boolean, :default => 0
    add_index "nodes", ["has_page"], :name => "page_flag_ndx"
  end
end
