# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class BlogsBlogpost < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :blogs
  self.table_name='wp_1_posts'
  self.primary_key = 'ID'

  belongs_to :blogs_user, foreign_key: 'post_author'

  scope :activity_entries, lambda{where("post_type IN ('post','page','revision')").where("post_status != 'future'")}


  def self.repoint(blog_id)
    begin
      self.table_name = "wp_#{blog_id}_posts"
      self.count
    rescue ActiveRecord::StatementInvalid
      self.table_name = "wp_1_posts"
      nil
    end
  end

end