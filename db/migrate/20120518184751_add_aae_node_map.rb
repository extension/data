class AddAaeNodeMap < ActiveRecord::Migration
  def change
    # groups
    create_table "aae_nodes", :force => true do |t|
      t.integer  "node_id"
      t.integer  "aae_id"
    end    
    add_index "aae_nodes", ["node_id","aae_id"], :name => "node_group_ndx"

  end

end
