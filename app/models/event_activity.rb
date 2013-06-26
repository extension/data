# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class EventActivity < ActiveRecord::Base
  extend YearMonth
  belongs_to :person

  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")

    # learn event activity
    LearnEventActivity.includes(:learner).where("activity IN (#{LearnEventActivity::TRANSFERRED_ACTIVITY.join(',')})").find_in_batches do |group|
      insert_values = []
      group.each do |activity|
        next if !(learner = activity.learner)
        next if learner.darmok_id.blank?
        insert_list = []
        insert_list << activity.event_id
        insert_list << learner.darmok_id
        insert_list << activity.trackable_id
        case activity.activity
        when LearnEventActivity::ANSWER
          insert_list << ActiveRecord::Base.quote_value('answer')
        when LearnEventActivity::RATING
          insert_list << ActiveRecord::Base.quote_value('rating')
        when LearnEventActivity::RATING_ON_COMMENT
          insert_list << ActiveRecord::Base.quote_value('rating')
        when LearnEventActivity::COMMENT
          insert_list << ActiveRecord::Base.quote_value('comment')
        when LearnEventActivity::COMMENT_ON_COMMENT
          insert_list << ActiveRecord::Base.quote_value('comment')
        when LearnEventActivity::CONNECT_BOOKMARK
          insert_list << ActiveRecord::Base.quote_value('bookmark')
        when LearnEventActivity::CONNECT_ATTEND
          insert_list << ActiveRecord::Base.quote_value('attend')
        when LearnEventActivity::CONNECT_WATCH
          insert_list << ActiveRecord::Base.quote_value('watch')
        else
          next
        end
        insert_list << ActiveRecord::Base.quote_value(activity.updated_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (event_id,person_id,item_id,activity_category,created_at) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end

    # learn edit activity
    LearnVersion.includes(:learner).where("item_type = 'Event'").find_in_batches do |group|
      insert_values = []
      group.each do |revision|
        next if !(learner = revision.learner)
        next if learner.darmok_id.blank?
        insert_list = []
        insert_list << revision.item_id
        insert_list << learner.darmok_id
        insert_list << revision.item_id
        insert_list << ActiveRecord::Base.quote_value('edit')
        insert_list << ActiveRecord::Base.quote_value(revision.created_at.to_s(:db))
        insert_values << "(#{insert_list.join(',')})"
      end
      insert_sql = "INSERT INTO #{self.table_name} (event_id,person_id,item_id,activity_category,created_at) VALUES #{insert_values.join(',')};"
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
      returndata['people'][person_id]['items'] = base_scope.count('DISTINCT(event_id)')
      returndata['people'][person_id]['actions'] = base_scope.count('id')
    end
    returndata
  end


end