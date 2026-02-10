class RemoveDuplicateExpenseParticipantsIndex < ActiveRecord::Migration[7.2]
  def change
    remove_index :expense_participants, name: "index_expense_participants_on_membership_id"
  end
end
