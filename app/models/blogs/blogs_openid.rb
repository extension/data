# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class BlogsOpenid < ActiveRecord::Base
  # connects to the blogs database
  self.establish_connection :blogs
  self.table_name='wp_openid_identities'
  self.primary_key = 'uurl_id'

  belongs_to :blogs_user, foreign_key: 'user_id'

end