# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Page < ActiveRecord::Base
  has_many :analytics
  has_many :page_taggings
  has_many :resource_tags, :through => :page_taggings
  belongs_to :node
  has_many :week_stats, :as => :statable

  # index settings
  NOT_INDEXED = 0
  INDEXED = 1
  NOT_GOOGLE_INDEXED = 2


  scope :not_ignored, :conditions =>["indexed != ?",NOT_INDEXED]  
  scope :indexed, :conditions => {:indexed => INDEXED}
  scope :articles, :conditions => {:datatype => 'Article'}
  scope :news, :conditions => {:datatype => 'News'}
  scope :faqs, :conditions => {:datatype => 'Faq'}
  scope :events, :conditions => {:datatype => 'Event'}
  
  def first_yearweek
    start_date = self.created_at.to_date+1.week
    cweek = start_date.cweek
    cwyear = start_date.cwyear
    [cwyear,cweek]
  end
  
  def eligible_weeks
    eligible_year_weeks.size
  end
  
  def eligible_year_weeks
    start_date = self.created_at.to_date + 1.week
    WeekStat.year_weeks_from_date(start_date)
  end
  
        
  def self.find_by_title_url(url)
   return nil unless url
   real_title = url.gsub(/_/, ' ')
   self.find_by_title(real_title)
  end
  
  
  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")    
    DarmokPage.find_in_batches do |group|
      insert_values = []
      group.each do |page|
        insert_list = []
        insert_list << page.id
        insert_list << (page.migrated_id.blank? ? 0 : page.migrated_id)
        insert_list << ActiveRecord::Base.quote_value(page.datatype)
        insert_list << ActiveRecord::Base.quote_value(page.title)
        insert_list << ActiveRecord::Base.quote_value(page.url_title)
        insert_list << (page.content_length.blank? ? 0 : page.content_length)
        insert_list << (page.content_words.blank? ? 0 : page.content_words)
        insert_list << ActiveRecord::Base.quote_value(page.source_created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.source_updated_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.source)
        insert_list << ActiveRecord::Base.quote_value(page.source_url)
        insert_list << page.indexed
        insert_list << (page.is_dpl? ? 1 : 0)
        insert_list << ActiveRecord::Base.quote_value(page.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.updated_at.to_s(:db))
        links = page.link_counts
        insert_list << links[:total]
        insert_list << links[:external]
        insert_list << links[:local]
        insert_list << links[:internal]
        insert_list << ActiveRecord::Base.quote_value(page.resource_tag_names.join(','))
        if(page.source = 'create' and page.source_url =~ %r{/node/(\d+)})
          insert_list << $1.to_i
        else
          insert_list << 0
        end
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
    PageTagging.rebuild
  end
  
end
