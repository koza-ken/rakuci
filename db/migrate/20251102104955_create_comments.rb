class CreateComments < ActiveRecord::Migration[7.2]
  def change
    create_table :comments do |t|
      t.references :card, null: false, foreign_key: true
      t.references :group_membership, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
