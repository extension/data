# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class Download < ActiveRecord::Base
  attr_accessible :label, :period, :filetype, :last_filesize, :objectclass, :objectmethod, :last_generated_at, :last_runtime, :method_writes_file, :is_private, :display_label

  # periods
  NONE = 0
  DAILY = 1
  WEEKLY = 2
  MONTHLY = 3


  scope :public, where(is_private: false)

  def filename
    now = Time.now.utc
    case self.period
    when NONE
      "#{Rails.root}/#{Settings.downloads_data_dir}/#{self.label}.#{self.filetype}"
    when DAILY
      "#{Rails.root}/#{Settings.downloads_data_dir}/#{self.label}_#{now.strftime("%Y-%m-%d")}.#{self.filetype}"
    when WEEKLY
      "#{Rails.root}/#{Settings.downloads_data_dir}/#{self.label}_#{now.strftime("%G-%V")}.#{self.filetype}"
    when MONTHLY
      "#{Rails.root}/#{Settings.downloads_data_dir}/#{self.label}_#{now.strftime("%Y-%m")}.#{self.filetype}"
    end
  end


  def dump_to_file(forceupdate=false)
    return nil if(self.in_progress? and !forceupdate)
    this_filename = self.filename
    if(!self.updated? or forceupdate)
      self.update_attributes(in_progress: true)
      object = Object.const_get(self.objectclass)
      benchmark = Benchmark.measure do
        if(self.method_writes_file)
          object.send(self.objectmethod,this_filename)
        else
          data = object.send(self.objectmethod)
          File.open(this_filename, 'w') {|f| f.write(data)}
        end
      end
      self.update_attributes(last_generated_at: Time.now, last_runtime: benchmark.real, last_filesize: File.size(this_filename), in_progress: false)
    end
    this_filename
  end

  def updated?
    File.exists?(self.filename)
  end

  def available_for_download?
    self.updated? and !self.in_progress?
  end

  def period_to_s
    case self.period
    when NONE
      'n/a'
    when DAILY
      'daily'
    when WEEKLY
      'weekly'
    when MONTHLY
      'monthly'
    end
  end


end