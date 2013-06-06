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


  scope :demographic_eligible, lambda{ where(demographic_eligible: true)}
  scope :evaluation_eligible, lambda{ where(evaluation_eligible: true)}


  def self.rebuild
    self.connection.execute("truncate table #{self.table_name};")
    insert_values = []
    AaeQuestion.includes(:location, :county, :original_group, :assigned_group, :submitter).not_rejected.find_in_batches(:batch_size => 100) do |question_group|
      insert_values = []
      question_group.each do |question|
        insert_list = []
        insert_list << question.id
        insert_list << self.quoted_value_or_null(question.user_ip)
        dl = question.detected_location
        dc = question.detected_county
        insert_list << (dl.blank? ? 'NULL' : dl.id)
        insert_list << (dc.blank? ? 'NULL' : dc.id)
        insert_list << self.value_or_null(question.location_id)
        insert_list << self.value_or_null(question.county_id)
        insert_list << self.value_or_null(question.original_location_id)
        insert_list << self.value_or_null(question.original_county_id)        
        insert_list << self.value_or_null(question.original_group_id)
        insert_list << self.name_or_null(question.original_group)
        insert_list << self.value_or_null(question.assigned_group_id)
        insert_list << self.name_or_null(question.assigned_group)
        insert_list << ActiveRecord::Base.quote_value(AaeQuestion::STATUS_TEXT[question.status_state])
        insert_list << (question.is_mobile?.nil? ? 'NULL' : question.is_mobile?)
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
        insert_list << question.demographic_eligible?
        insert_list << question.evaluation_eligible?
        insert_values << "(#{insert_list.join(',')})"
      end # question_group
      columns = self.column_names
      insert_sql = "INSERT INTO #{self.table_name} (#{columns.join(',')}) VALUES #{insert_values.join(',')};"
      self.connection.execute(insert_sql)
    end # all questions
  end

  def self.quoted_value_or_null(value)
    value.blank? ? 'NULL' : ActiveRecord::Base.quote_value(value)
  end

  def self.value_or_null(value)
    value.blank? ? 'NULL' : value
  end

  def self.name_or_null(item)
    item.nil? ? 'NULL' : ActiveRecord::Base.quote_value(item.name)
  end

  def self.name_or_nil(item)
    item.nil? ? nil : item.name
  end

  def self.questions_csv(filename)
    with_scope do
      question_columns = [
        'question_id',
        'detectable_location',
        'detected_location',
        'detected_location_fips',
        'detected_county',
        'detected_county_fips',
        'location',
        'location_fips',
        'location_changed',
        'county',
        'county_fips',
        'county_changed',
        'original_group_id',
        'original_group',
        'assigned_group_id',
        'assigned_group',
        'status',
        'submitted_from_mobile',
        'submitted_at',
        'submitter_id',
        'submitter_is_extension',        
        'aae_version',
        'source',
        'comment_count',
        'submitter_response_count',
        'expert_response_count',
        'expert_responders',
        'initial_response_at',
        'initial_responder_id',
        'initial_responder_name',
        'initial_responder_location',
        'initial_responder_location_fips',  
        'initial_responder_county',
        'initial_responder_county_fips',
        'initial_response_time',
        'mean_response_time',
        'median_response_time',
        'demographic_eligible',
        'evaluation_eligible',
        'tags'
      ]
      CSV.open(filename,'wb') do |csv|
        headers = []
        question_columns.each do |column|
          headers << column
        end
        csv << headers
        self.includes(:detected_location, :detected_county, :location, :county).find_in_batches do |question_group|
          question_group.each do |question|
            row = []
            row << question.id
            row << (!question.ip_address.blank?)
            row << self.name_or_nil(question.detected_location)
            row << ((question.detected_location.nil?) ? nil : question.detected_location.fips)
            row << self.name_or_nil(question.detected_county)
            row << ((question.detected_county.nil?) ? nil : question.detected_county.fips)
            row << self.name_or_nil(question.location)
            row << ((question.location.nil?) ? nil : question.location.fips)
            row << (question.location_id == question.original_location_id)            
            row << self.name_or_nil(question.county)
            row << ((question.county.nil?) ? nil : question.county.fips)
            row << (question.county_id == question.original_county_id)                  
            row << question.original_group_id
            row << question.original_group_name
            row << question.assigned_group_id
            row << question.assigned_group_name
            row << question.status
            row << question.submitted_from_mobile?
            row << question.submitted_at.utc.strftime("%Y-%m-%d %H:%M:%S")
            row << question.submitter_id
            row << question.submitter_is_extension?
            row << question.aae_version
            row << question.source
            row << question.comment_count
            row << question.submitter_response_count
            row << question.expert_response_count
            row << question.expert_responders       
            if(responder = question.initial_responder)
              row << question.initial_response_at.utc.strftime("%Y-%m-%d %H:%M:%S")
              row << responder.id
              row << responder.fullname
              row << self.name_or_nil(responder.location)              
              row << ((responder.location.nil?) ? nil : responder.location.fips)
              row << self.name_or_nil(responder.county)
              row << ((responder.county.nil?) ? nil : responder.county.fips)
              row << question.initial_response_time
              row << question.mean_response_time
              row << question.median_response_time
            else
              row << nil # response_at
              row << nil # id
              row << nil # name
              row << nil # location
              row << nil # location_fips
              row << nil # county
              row << nil # county_fips
              row << nil # response_time
              row << nil # mean
              row << nil # median
            end
            row << question.demographic_eligible?
            row << question.evaluation_eligible?            
            row << question.tags
            csv << row
          end # question
        end # question group
      end # csv 
    end # with_scope

  end



 
end