class AddYearweeksToDiffs < ActiveRecord::Migration
  def change
    execute "ALTER TABLE `page_diffs` ADD COLUMN `yearweek` INT(11) NULL DEFAULT 0  AFTER `page_id`;"
  end
end
