# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class BlogsBlogcomment < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :blogs
  self.table_name='wp_1_comments'
  self.primary_key = 'comment_ID'

  belongs_to :blogs_user, foreign_key: 'user_id'

  scope :user_activities, lambda{where("user_id > 0").where('comment_approved = 1')}

  def self.repoint(blog_id)
    begin
      self.table_name = "wp_#{blog_id}_comments"
      self.count
    rescue ActiveRecord::StatementInvalid
      self.table_name = "wp_1_comments"
      nil
    end
  end

end