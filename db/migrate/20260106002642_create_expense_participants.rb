class CreateExpenseParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :expense_participants do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :group_membership, null: false, foreign_key: true

      t.timestamps
    end

    add_index :expense_participants, [:expense_id, :group_membership_id], unique: true, name: "index_expense_participants_unique"
    add_index :expense_participants, :expense_id
    add_index :expense_participants, :group_membership_id, name: "index_expense_participants_on_membership_id"
  end
end
