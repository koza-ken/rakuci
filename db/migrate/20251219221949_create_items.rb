class CreateItems < ActiveRecord::Migration[7.2]
  def change
    create_table :items do |t|
      t.integer :item_list_id, null: false
      t.string :name, limit: 100, null: false
      t.boolean :checked, null: false, default: false
      t.integer :position

      t.timestamps
    end

    add_index :items, :item_list_id, name: "index_items_on_item_list_id"
    add_index :items, [:item_list_id, :position], name: "index_items_on_list_and_position"
    add_foreign_key :items, :item_lists
  end
end
