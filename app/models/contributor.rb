# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Contributor < ActiveRecord::Base
  has_many :node_activities
  has_many :node_metacontributions

  # note! not unique!
  has_many :meta_contributed_nodes, :through => :node_metacontributions, :source => :node
  has_many :meta_contributed_pages, :through => :meta_contributed_nodes, :source => :page
  has_many :contributed_nodes, :through => :node_activities, :source => :node
  has_many :contributed_pages, :through => :contributed_nodes, :source => :page


  def fullname 
    "#{self.first_name} #{self.last_name}"
  end

  def contributions_by_page
    self.contributed_pages.group("pages.id").select("pages.*, group_concat(node_activities.event) as contributions")
  end

  def contributions_by_node
    self.contributed_nodes.group("nodes.id").select("nodes.*, group_concat(node_activities.event) as contributions")
  end

   def meta_contributions_by_page
    self.meta_contributed_pages.group("pages.id").select("pages.*, group_concat(node_metacontributions.role) as metacontributions")
  end

  def meta_contributions_by_node
    self.meta_contributed_nodes.group("nodes.id").select("nodes.*, group_concat(node_metacontributions.role) as metacontributions")
  end

  def contributions_count(node_type)
    counts = {}
    counts[:items] = self.node_activities.send(node_type).count('node_id',:distinct => true)
    counts[:actions] = self.node_activities.send(node_type).count    
    counts[:byaction] = self.node_activities.send(node_type).group('event').count
    counts
  end

  def metacontributions_count(node_type)
    counts = {}
    counts[:items] = self.node_metacontributions.send(node_type).count('node_id',:distinct => true)
    counts[:actions] = self.node_metacontributions.send(node_type).count    
    counts[:byaction] = self.node_metacontributions.send(node_type).group('role').count
    counts
  end 


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")    
    insert_values = []
    DarmokAccount.where(:vouched => true).where(:type => 'User').all.each do |da|
      insert_list = []
      insert_list << da.id
      insert_list << ActiveRecord::Base.quote_value(da.login)
      insert_list << ActiveRecord::Base.quote_value(da.first_name)
      insert_list << ActiveRecord::Base.quote_value(da.last_name)
      insert_list << ActiveRecord::Base.quote_value(da.email)
      insert_list << ActiveRecord::Base.quote_value(da.title)
      insert_list << (da.account_status || 0)
      last_login = da.last_login_at || da.created_at
      insert_list << ActiveRecord::Base.quote_value(last_login.to_s(:db))
      insert_list << (da.position_id || 0)
      insert_list << (da.location_id || 0)
      insert_list << (da.county_id || 0)
      insert_list << da.retired
      insert_list << da.is_admin
      insert_list << (da.primary_account_id || 0)
      insert_list << ActiveRecord::Base.quote_value(da.created_at.to_s(:db))
      insert_list << ActiveRecord::Base.quote_value(da.updated_at.to_s(:db))      
      insert_values << "(#{insert_list.join(',')})"
    end
    insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
    self.connection.execute(insert_sql)
  end

end
