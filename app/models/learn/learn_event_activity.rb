# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class LearnEventActivity < ActiveRecord::Base
  # connects to the learn database
  self.establish_connection :learn
  self.table_name='event_activities'

  # types of activities - gaps are between types
  # in case we may need to group/expand
  VIEW                      = 1
  VIEW_FROM_RECOMMENDATION  = 2
  VIEW_FROM_SHARE           = 3
  SHARE                     = 11
  ANSWER                    = 21
  RATING                    = 31
  RATING_ON_COMMENT         = 32
  COMMENT                   = 41
  COMMENT_ON_COMMENT        = 42
  CONNECT                   = 50
  CONNECT_PRESENTER         = 51
  CONNECT_BOOKMARK          = 52
  CONNECT_ATTEND            = 53
  CONNECT_WATCH             = 54

  TRANSFERRED_ACTIVITY = [ANSWER,RATING,RATING_ON_COMMENT,COMMENT,COMMENT_ON_COMMENT,CONNECT_BOOKMARK,CONNECT_ATTEND,CONNECT_WATCH]

  belongs_to :learner, class_name: 'LearnLearner'
end