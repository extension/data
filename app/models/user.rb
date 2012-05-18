# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class User < ActiveRecord::Base


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
