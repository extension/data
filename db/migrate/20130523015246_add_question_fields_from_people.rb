class AddQuestionFieldsFromPeople < ActiveRecord::Migration
  def change
    add_column(:questions, 'ip_address', :string)
    add_column(:questions, 'original_location_id', :integer)
    add_column(:questions, 'original_county_id', :integer)
  end
end
