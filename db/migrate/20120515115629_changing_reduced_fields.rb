class ChangingReducedFields < ActiveRecord::Migration
  def change
    remove_column "raw_analytics", "reduced_path"
    add_column "raw_analytics", 'url_type', :string
    add_column "raw_analytics", 'url_page_id', :integer
    add_column "raw_analytics", 'url_migrated_id', :integer
    add_column "raw_analytics", 'url_wiki_title', :string
  end

end
