class DumpResourceTags < ActiveRecord::Migration
  def up
    remove_column('pages','resource_tag_names')
    rename_column('page_taggings','resource_tag_id','tag_id')
    rename_column('week_totals','resource_tag_id','tag_id')
    rename_column('total_diffs','resource_tag_id','tag_id')
    drop_table('resource_tags')
  end
end
