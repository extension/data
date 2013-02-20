class DropAaeNode < ActiveRecord::Migration
  def up
    drop_table('aae_nodes')
  end

end
