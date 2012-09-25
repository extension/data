# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Rebuild < ActiveRecord::Base

  CREATE_REBUILDS = ['Node','NodeGroup','Revision','AaeNode','NodeActivity','NodeMetacontribution']
  DARMOK_REBUILDS = ['Page','Group','Tag','PageTagging','Contributor','ContributorGroup']
  INTERNAL_REBUILDS = ['PageStat','LandingStat','PageTotal',{'CollectedPageStat' => 'rebuild'}]


  def run_and_log(model,action)
    object = Module.const_get(model)
    self.update_attributes(current_model: model, current_action: action, current_start: Time.now)
    benchmark = Benchmark.measure do
      object.send(action)
    end
    UpdateTime.log(self,model,action,benchmark.real)
    self.update_attributes(current_model: '', current_action: '', current_start: '')
    benchmark.real
  end

  def self.do_it(group)
    rebuild = start(group)
    results = rebuild.rebuild_all
    rebuild.finish
    results
  end

  def self.single_do_it(model,action)
    rebuild = start_single(model,action)
    results = rebuild.rebuild_all
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

  def rebuild_list
    case self.group
    when 'all'
      list = DARMOK_REBUILDS + CREATE_REBUILDS + INTERNAL_REBUILDS
    when 'create'
      list = CREATE_REBUILDS
    when 'darmok'
      list = DARMOK_REBUILDS
    when 'internal'
      list = INTERNAL_REBUILDS
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

  def rebuild_all
    results = {}
    rebuild_list.each do |(model,action)|
      results["#{model}.#{action}"] = run_and_log(model,action)
    end
    results
  end

  def self.latest
    order('created_at DESC').first
  end

end