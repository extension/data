class AddOpenIdField < ActiveRecord::Migration
  def change
    execute "ALTER TABLE `contributors` ADD COLUMN `openid_uid` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL AFTER `idstring`;"
    execute "UPDATE `contributors` set `openid_uid` = CONCAT('https://people.extension.org/',idstring) WHERE 1"
    add_index "contributors", ["openid_uid"], :name => "openid_ndx"
  end

end
