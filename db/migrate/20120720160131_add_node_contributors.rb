class AddNodeContributors < ActiveRecord::Migration
  def change
    
    create_table "node_contributors", :force => true do |t|
      t.integer  "node_id"
      t.integer  "user_id"
      t.integer  "node_revision_id"
      t.string   "role"
      t.string   "author"
      t.datetime "contributed_at"
      t.datetime "created_at"
    end
    
    add_index "node_contributors", ["node_id"], :name => "node_ndx"
    add_index "node_contributors", ["user_id"], :name => "user_ndx"
    
    
  end
  
  # CREATE TABLE `field_data_field_contributors` (
  #   `entity_type` varchar(128) NOT NULL DEFAULT '' COMMENT 'The entity type this data is attached to',
  #   `bundle` varchar(128) NOT NULL DEFAULT '' COMMENT 'The field instance bundle to which this row belongs, used when deleting a field instance',
  #   `deleted` tinyint(4) NOT NULL DEFAULT '0' COMMENT 'A boolean indicating whether this data item has been deleted',
  #   `entity_id` int(10) unsigned NOT NULL COMMENT 'The entity id this data is attached to',
  #   `revision_id` int(10) unsigned DEFAULT NULL COMMENT 'The entity revision id this data is attached to, or NULL if the entity type is not versioned',
  #   `language` varchar(32) NOT NULL DEFAULT '' COMMENT 'The language for this data item.',
  #   `delta` int(10) unsigned NOT NULL COMMENT 'The sequence number for this data item, used for multi-value fields',
  #   `field_contributors_contribution_role` varchar(60) DEFAULT NULL,
  #   `field_contributors_contribution_author` varchar(255) DEFAULT NULL,
  #   `field_contributors_contribution_date` int(11) DEFAULT '0',
  #   PRIMARY KEY (`entity_type`,`entity_id`,`deleted`,`delta`,`language`),
  #   KEY `entity_type` (`entity_type`),
  #   KEY `bundle` (`bundle`),
  #   KEY `deleted` (`deleted`),
  #   KEY `entity_id` (`entity_id`),
  #   KEY `revision_id` (`revision_id`),
  #   KEY `language` (`language`)
  # ) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Data storage for field 23 (field_contributors)'
end
