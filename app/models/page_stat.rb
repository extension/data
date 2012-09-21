# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class PageStat < ActiveRecord::Base
  extend YearWeek
  belongs_to :page
  attr_accessible :page_id, :pageviews, :unique_pageviews, :year, :week, :entrances, :time_on_page, :exits, :visitors, :new_visits


  scope :by_year_week, lambda {|year,week| where(:year => year).where(:week => week) }
  scope :articles, includes(:page).where('pages.datatype = ?','Article')
  scope :news, includes(:page).where('pages.datatype = ?','News')
  scope :faqs, includes(:page).where('pages.datatype = ?','Faq')
  scope :events, includes(:page).where('pages.datatype = ?','Event')
  scope :indexed, includes(:page).where("pages.indexed = ?",Page::INDEXED)


  def self.mass_create_or_update_for_pages(year,week)
    select_statement = <<-END
    page_id,yearweek,year,week,
    SUM(pageviews) as pageviews,
    SUM(entrances) as entrances,
    SUM(unique_pageviews) as unique_pageviews,
    SUM(time_on_page) as time_on_page,
    SUM(exits) AS exits,
    SUM(visitors) AS visitors,
    SUM(new_visits) AS new_visits
    END

    analytics = Analytic.select(select_statement).where('page_id IS NOT NULL').where(:year => year).where(:week => week).group("page_id,yearweek")

    analytics.each do |analytic|
      create_options = {}
      create_options[:pageviews] = analytic.pageviews
      create_options[:unique_pageviews] = analytic.unique_pageviews
      create_options[:entrances] = analytic.entrances
      create_options[:time_on_page] = analytic.time_on_page
      create_options[:exits] = analytic.exits
      create_options[:visitors] = analytic.visitors
      create_options[:new_visits] = analytic.new_visits


      begin
        self.create(create_options.merge({:page_id => analytic.page_id, :yearweek => yearweek_string.to_i, :year => year, :week => week}))
      rescue ActiveRecord::RecordNotUnique
        if(weekstat = WeekStat.where(:page_id => analytic.page_id).where(:year => year).where(:week => week).first)
          weekstat.update_attributes(create_options)
        end
      end
    end
  end

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    # don't insert records earlier than first yearweek
    (e_year,e_week) = Page.earliest_year_week
    earliest_year_week_string = Analytic.yearweek_string(e_year,e_week)
    insert_columns = ['page_id','yearweek','year','week','yearweek_date','pageviews','entrances','unique_pageviews','time_on_page','exits','visitors','new_visits','created_at','updated_at']
    select_statement = <<-END
    page_id,
    yearweek,
    year,
    week,
    STR_TO_DATE(CONCAT(yearweek,' Sunday'), '%X%V %W'),
    SUM(pageviews) as pageviews,
    SUM(entrances) as entrances,
    SUM(unique_pageviews) as unique_pageviews,
    SUM(time_on_page) as time_on_page,
    SUM(exits) AS exits,
    SUM(visitors) AS visitors,
    SUM(new_visits) AS new_visits,
    NOW() as created_at,
    NOW() as updated_at
    END
    where_clause = "yearweek >= #{earliest_year_week_string} AND page_id IS NOT NULL"
    group_by = "page_id,yearweek"
    sql_statement = "INSERT INTO #{self.table_name} (#{insert_columns.join(', ')}) SELECT #{select_statement} FROM #{Analytic.table_name} WHERE #{where_clause} GROUP BY #{group_by}"
    self.connection.execute(sql_statement)

    # go back and clear out stats earlier than first page created_at
    delete_statement = "DELETE #{self.table_name}.* FROM #{self.table_name},#{Page.table_name} WHERE #{self.table_name}.page_id = #{Page.table_name}.id and #{self.table_name}.yearweek < YEARWEEK(#{Page.table_name}.created_at,3)"
    self.connection.execute(delete_statement)

  end







end