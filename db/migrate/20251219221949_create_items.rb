class CreateItems < ActiveRecord::Migration[7.2]
  def change
    create_table :items do |t|
      t.integer :item_list_id
      t.string :name
      t.boolean :checked
      t.integer :position

      t.timestamps
    end
  end
end
