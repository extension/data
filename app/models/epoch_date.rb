# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class EpochDate
  # earliest google analytics data
  GA_START                      = Date.parse('2007-02-23')
  
  # in preparation for the eXtension launch, existing content
  # was republished into the new www site under development
  # this is the early content "created at" date we have in the
  # www data
  WWW_CONTENT_START             = Date.parse('2008-02-05')
  
  # eXtension National launch
  WWW_LAUNCH                    = Date.parse('2008-02-21')
  
  # New content marked as "noindex" so that Google wouldn't
  # index the largely duplicate news content
  WWW_NEWS_NOINDEX              = Date.parse('2010-11-03')

  # the day after Google's "panda" search algorithm change
  # was released.
  POST_PANDA                    = Date.parse('2011-02-28')
  
  # www faq/article/news/event urls modified to be 
  # all /pages/id/seo-friendly-title
  WWW_URL_REVAMP                = Date.parse('2011-03-19')
  
  # the day after Google's "panda" search algorithm change
  # was released globally
  POST_GLOBAL_PANDA             = Date.parse('2011-04-12')
  
  # after analyzing all content, we marked any page not getting
  # more than one entrance from Google Search per week on 
  # average
  WWW_LOW_PEFORM_NOINDEX        = Date.parse('2011-05-27')
  
  # noindex experiment had no apparent effect on traffic
  # all faqs, articles, events marked as "index"
  WWW_REINDEX_AFE               = Date.parse('2011-07-12')
         
  
  # actual migration date is one day prior
  
  # ag energy and animal manure management content migrated
  CREATE_PILOT_WIKI_MIGRATION   = Date.parse('2011-05-06')
  
  # bulk of content migrated to create
  CREATE_FIRST_WIKI_MIGRATION   = Date.parse('2011-06-18')
  
  # faqs migrated to create
  CREATE_FAQ_MIGRATION          = Date.parse('2011-06-23')
  
  # all copwiki content migrated to create
  CREATE_FINAL_WIKI_MIGRATION   = Date.parse('2011-07-09')
end