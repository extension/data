class AddTagsToAnalytics < ActiveRecord::Migration
  def change
  	# for tag landing pages
  	add_column("analytics", "tag_id", :integer)
  	add_index("analytics",["tag_id"],:name => 'tag_id_ndx')

  	# go back and associate old records
  	Analytic.reset_column_information
  	Analytic.where(:url_type => Analytic::URL_OTHER).find_each do |lytic|
  		lytic.set_url_type
      lytic.save!
    end
    
  end
end
