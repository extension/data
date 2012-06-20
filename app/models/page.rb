# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Page < ActiveRecord::Base
  has_many :analytics
  has_many :page_taggings
  has_many :tags, :through => :page_taggings
  belongs_to :node
  has_many :week_stats
  has_many :week_diffs
  has_one :page_total

  # index settings
  NOT_INDEXED = 0
  INDEXED = 1
  NOT_GOOGLE_INDEXED = 2


  scope :not_ignored, where("indexed != ?",NOT_INDEXED )
  scope :indexed, where(:indexed => INDEXED)
  scope :articles, where(:datatype => 'Article')
  scope :news, where(:datatype => 'News')
  scope :faqs, where(:datatype => 'Faq')
  scope :events, where(:datatype => 'Event')
  scope :created_since, lambda{|date| where("#{self.table_name}.created_at >= ?",date)}
  scope :from_create, where(:source => 'create')
  scope :by_datatype, lambda{|datatype| where(:datatype => datatype)}
  
  def self.earliest_year_week
    if(@yearweek.blank?)
      earliest_date = self.minimum(:created_at).to_date
      @yearweek = [earliest_date.cwyear,earliest_date.cweek]
    end
    @yearweek
  end      
      
  def eligible_weeks(fractional = false)
    if(fractional)
      eligible_year_weeks.size + ((7-self.created_at.to_date.cwday) / 7)
    else
      eligible_year_weeks.size
    end
  end
  
  def eligible_year_weeks
    start_date = self.created_at.to_date + 1.week
    Analytic.year_weeks_from_date(start_date)
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
        links = page.link_counts
        insert_list << links[:total]
        insert_list << links[:external]
        insert_list << links[:local]
        insert_list << links[:internal]
        if(page.source == 'create' and page.source_url =~ %r{/node/(\d+)})
          insert_list << $1.to_i
        else
          insert_list << 0
        end
        insert_list << ActiveRecord::Base.quote_value(page.created_at.to_s(:db))
        insert_list << ActiveRecord::Base.quote_value(page.updated_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
  end
  
  def self.pagecount_for_yearweek(year,week)
    yearweek_string = "#{year}" + "%02d" % week
    with_scope do
      self.where("YEARWEEK(#{self.table_name}.created_at,3) <= ?",yearweek_string).count
    end
  end
  
  def self.page_counts_by_yearweek
    with_scope do
      self.group("YEARWEEK(#{self.table_name}.created_at,3)").count
    end
  end
  
  
  def self.datatypes
    self.group(:datatype).pluck(:datatype)
  end

  
  
end
