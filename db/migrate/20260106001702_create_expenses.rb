class CreateExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :expenses do |t|
      t.references :group, null: false, foreign_key: true
      t.references :paid_by_membership, null: false, foreign_key: { to_table: :group_memberships }
      t.string :name, limit: 100, null: false
      t.integer :amount, null: false
      t.text :memo
      t.date :paid_at, null: false

      t.timestamps
    end

    add_index :expenses, :group_id
  end
end
