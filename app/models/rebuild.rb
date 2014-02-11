# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Rebuild < ActiveRecord::Base
  attr_accessible :group, :single_model, :single_action, :in_progress, :started, :finished, :run_time, :current_model, :current_action, :current_start

  ANALYTIC_IMPORTS = [{'Analytic' => 'import_analytics'}]
  CREATE_REBUILDS = ['Node','NodeGroup','Revision','NodeActivity','NodeMetacontribution']
  DARMOK_REBUILDS = ['Page','Tag','PageTagging']
  PEOPLE_REBUILDS = ['Group','Contributor','ContributorGroup']
  INTERNAL_REBUILDS = ['PageStat','LandingStat','PageTotal','CollectedPageStat']
  AAE_REBUILDS = ['Question','QuestionAssignment','QuestionActivity']
  LEARN_REBUILDS = ['EventActivity']
  BLOGS_REBUILDS = ['BlogsActivity']

  CACHE_REBUILDS = [{'Node' => 'rebuild_activity_cache'}]

  def run_and_log(model,action)
    object = Object.const_get(model)
    self.update_attributes(current_model: model, current_action: action, current_start: Time.now)
    results = ''
    benchmark = Benchmark.measure do
      results = object.send(action)
    end
    UpdateTime.log(self,model,action,benchmark.real,results)
    self.update_attributes(current_model: '', current_action: '', current_start: '')
    benchmark.real
  end

  def self.do_it(group)
    rebuild = start(group)
    results = rebuild.run_all
    rebuild.finish
    results
  end

  def self.single_do_it(model,action)
    rebuild = start_single(model,action)
    results = rebuild.run_all
    rebuild.finish
    results
  end

  def self.start(group)
    self.create(group: group, in_progress: true, started: Time.now)
  end

  def self.start_single(model,action)
    self.create(group: 'single', single_model: model, single_action: action, in_progress: true, started: Time.now)
  end

  def finish
    finished = Time.now
    self.update_attributes(in_progress: false, finished: finished, run_time: (finished - started))
  end

  def list_of_rebuilds
    case self.group
    when 'all'
      list = PEOPLE_REBUILDS + DARMOK_REBUILDS + CREATE_REBUILDS + ANALYTIC_IMPORTS + INTERNAL_REBUILDS + AAE_REBUILDS + LEARN_REBUILDS + BLOGS_REBUILDS + CACHE_REBUILDS
    when 'blogs'
      list = BLOGS_REBUILDS 
    when 'create'
      list = CREATE_REBUILDS
    when 'darmok'
      list = DARMOK_REBUILDS
    when 'people'
      list = PEOPLE_REBUILDS
    when 'internal'
      list = INTERNAL_REBUILDS
    when 'analytics'
      list = ANALYTIC_IMPORTS
    when 'cache'
      list = CACHE_REBUILDS
    when 'aae'
      list = AAE_REBUILDS
    when 'learn'
      list = LEARN_REBUILDS
    when 'single'
      list = [{self.single_model => self.single_action}]
    end

    returnlist = []
    list.each do |item|
      if(item.is_a?(String))
        returnlist << [item,'rebuild']
      elsif(item.is_a?(Hash))
        item.each do |model,action|
          returnlist << [model,action]
        end
      end
    end
    returnlist
  end

  def run_all
    results = {}
    list_of_rebuilds.each do |(model,action)|
      results["#{model}.#{action}"] = run_and_log(model,action)
    end
    results
  end

  def self.latest
    order('created_at DESC').first
  end

end