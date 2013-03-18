# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Question < ActiveRecord::Base

  belongs_to :initial_responder, class_name: 'Contributor'
  belongs_to :detected_location, class_name: 'Location'
  belongs_to :location
  belongs_to :detected_county, class_name: 'County'
  belongs_to :county



  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    AaeQuestion.includes(:location, :county, :original_group, :assigned_group, :submitter).not_rejected.find_in_batches(:batch_size => 100) do |question_group|
      insert_values = []
      question_group.each do |question|
        insert_list = []
        insert_list << question.id
        dl = question.detected_location
        dc = question.detected_county
        insert_list << (dl.blank? ? 'NULL' : dl.id)
        insert_list << (dc.blank? ? 'NULL' : dc.id)
        insert_list << self.value_or_null(question.location_id)
        insert_list << self.value_or_null(question.county_id)
        insert_list << self.value_or_null(question.original_group_id)
        insert_list << self.name_or_null(question.original_group)
        insert_list << self.value_or_null(question.assigned_group_id)
        insert_list << self.name_or_null(question.assigned_group)
        insert_list << ActiveRecord::Base.quote_value(AaeQuestion::STATUS_TEXT[question.status_state])
        insert_list << (question.is_mobile? ? 1 : 0)
        insert_list << ActiveRecord::Base.quote_value(question.created_at.utc.to_s(:db))
        insert_list << self.value_or_null(question.submitter_id)
        insert_list << (question.submitter.blank? ? 'NULL' : (question.submitter.has_exid? ? 1 : 0))
        insert_list << question.aae_version
        insert_list << ActiveRecord::Base.quote_value(question.source)
        insert_list << question.comments.count
        insert_list << question.responses.non_expert.count
        insert_list << question.responses.expert.count
        insert_list << question.responses.expert.count('distinct(resolver_id)')            
        if(response = question.initial_response)
          insert_list << ActiveRecord::Base.quote_value(response.created_at.utc.to_s(:db))
          if(resolver = response.resolver)
            insert_list << self.value_or_null(response.resolver.darmok_id)
          else
            insert_list << 'NULL'
          end
          insert_list << (response.time_since_last / 3600).to_f
          if(!question.response_times.blank?)
            insert_list << (question.response_times.mean / 3600).to_f
            insert_list << (question.response_times.median / 3600).to_f
          else
            insert_list << 'NULL' # mean
            insert_list << 'NULL' # median
          end                
        else
          insert_list << 'NULL' # response_at
          insert_list << 'NULL' # id
          insert_list << 'NULL' # response_time
          insert_list << 'NULL' # mean
          insert_list << 'NULL' # median
        end
        insert_list << (question.tags.count > 0 ? ActiveRecord::Base.quote_value(question.tags.map(&:name).join(',')) : 'NULL')
        insert_values << "(#{insert_list.join(',')})"
      end # question_group
      columns = self.column_names
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end # all questions
  end

  def self.value_or_null(value)
    value.blank? ? 'NULL' : value
  end

  def self.name_or_null(item)
    item.nil? ? 'NULL' : ActiveRecord::Base.quote_value(item.name)
  end



 
end