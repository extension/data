class BlogNamesAreStringsYouFool < ActiveRecord::Migration
  def change
    change_column(:blogs_activities, :blog_name, :string)
  end

end
