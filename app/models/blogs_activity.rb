# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class BlogsActivity < ActiveRecord::Base
  extend YearMonth
  belongs_to :person


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")

    BlogsBlog.order(:blog_id).each do |blog|
      blog_id = blog.blog_id
      blog_name = blog.path.gsub('/','')
      blog_name = 'root' if(blog_name.blank?)

      # edits
      postcount = BlogsBlogpost.repoint(blog_id)
      next if(postcount.nil? or postcount == 0)
      next if(BlogsBlogpost.activity_entries.count == 0)
      insert_values = []     
      BlogsBlogpost.includes(:blogs_user => :blogs_openid).activity_entries.each do |posting|
        next if !(user = posting.blogs_user)
        next if !(openid = user.blogs_openid)
        insert_list = []
        insert_list << posting.post_author
        insert_list << blog_id
        insert_list << ActiveRecord::Base.quote_value(blog_name)
        insert_list << posting.post_parent
        insert_list << posting.ID
        insert_list << ActiveRecord::Base.quote_value("#{blog_id}::#{posting.post_parent}")
        insert_list << ActiveRecord::Base.quote_value('edit')
        insert_list << ActiveRecord::Base.quote_value(posting.post_date.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (person_id,blog_id,blog_name,post_id,item_id,compound_post_id,activity_category,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)

      commentcount = BlogsBlogcomment.repoint(blog_id)
      next if(commentcount.nil? or commentcount == 0)
      next if (BlogsBlogcomment.user_activities.count == 0)
      insert_values = []     
      BlogsBlogcomment.includes(:blogs_user => :blogs_openid).user_activities.each do |comment|
        next if !(user = comment.blogs_user)
        next if !(openid = user.blogs_openid)
        insert_list = []
        insert_list << comment.user_id
        insert_list << blog_id
        insert_list << ActiveRecord::Base.quote_value(blog_name)
        insert_list << comment.comment_post_ID
        insert_list << comment.comment_ID
        insert_list << ActiveRecord::Base.quote_value("#{blog_id}::#{comment.comment_post_ID}")
        insert_list << ActiveRecord::Base.quote_value('comment')
        insert_list << ActiveRecord::Base.quote_value(comment.comment_date.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (person_id,blog_id,blog_name,post_id,item_id,compound_post_id,activity_category,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end
  end

  def self.maximum_data_date 
    self.maximum(:created_at).to_date
  end  


  def self.periodic_activity_by_person_id(options = {})
    returndata = {}
    months = options[:months]
    end_date = options[:end_date]
    start_date = end_date - months.months
    persons = self.where("DATE(created_at) >= ?",start_date).where('person_id > 1').pluck('person_id').uniq
    returndata['months'] = months
    returndata['start_date'] = start_date
    returndata['end_date'] = end_date
    returndata['people_count'] = persons.size
    returndata['people'] = {}
    persons.each do |person_id|
      returndata['people'][person_id] ||= {}
      base_scope = self.where("DATE(created_at) >= ?",start_date).where('person_id = ?',person_id)
      returndata['people'][person_id]['dates'] = base_scope.pluck('DATE(created_at)').uniq
      returndata['people'][person_id]['days'] = returndata['people'][person_id]['dates'].size
      returndata['people'][person_id]['items'] = base_scope.count('DISTINCT(compound_post_id)')
      returndata['people'][person_id]['actions'] = base_scope.count('id')
    end
    returndata
  end


end