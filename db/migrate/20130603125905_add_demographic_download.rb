class AddDemographicDownload < ActiveRecord::Migration
  def up

    Download.create(label: 'aae_demographics', 
                    display_label: 'Ask an Expert Demographics',
                    objectclass: 'AaeUser', 
                    objectmethod: 'demographics_data_csv', 
                    filetype: 'csv', 
                    period: Download::WEEKLY,
                    method_writes_file: true, 
                    is_private: false)

    Download.create(label: 'aae_demographics_private', 
                    display_label: 'Ask an Expert Demographics (Private)',
                    objectclass: 'AaeUser', 
                    objectmethod: 'demographics_private_data_csv', 
                    filetype: 'csv', 
                    period: Download::WEEKLY,
                    method_writes_file: true, 
                    is_private: true)

  end
end
