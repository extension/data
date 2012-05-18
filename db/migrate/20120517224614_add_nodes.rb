class AddNodes < ActiveRecord::Migration
  def change
    add_column "pages", "node_id", :integer
    add_index "pages", ["node_id"], :name => "node_ndx"
        
    # nodes
    create_table "nodes", :force => true do |t|
      t.integer  "revision_id"
      t.string   "node_type"
      t.string     "title"
      t.timestamps
    end    
  end
end
