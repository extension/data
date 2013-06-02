class AddQuestionEligibility < ActiveRecord::Migration
  def change
    add_column(:questions, 'demographic_eligible', :boolean)
    add_column(:questions, 'evaluation_eligible', :boolean)
  end

end
