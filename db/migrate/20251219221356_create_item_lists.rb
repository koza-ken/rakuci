class CreateItemLists < ActiveRecord::Migration[7.2]
  def change
    create_table :item_lists do |t|
      t.string :listable_type, null: false
      t.integer :listable_id, null: false
      t.string :name, limit: 100

      t.timestamps
    end

    add_index :item_lists, [:listable_type, :listable_id], unique: true, name: "index_item_lists_on_listable"
  end
end
