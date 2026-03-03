class RenameItemListsAndItemsToPackingListsAndPackingItems < ActiveRecord::Migration[7.2]
  def change
    # テーブルリネーム
    rename_table :item_lists, :packing_lists
    rename_table :items, :packing_items

    # 外部キーのカラム名リネーム
    # ※ 単カラムインデックス (index_items_on_item_list_id) は rename_column で自動リネームされる
    rename_column :packing_items, :item_list_id, :packing_list_id

    # 複合インデックスとポリモーフィックインデックスは自動リネームされないため手動で変更
    rename_index :packing_lists, :index_item_lists_on_listable, :index_packing_lists_on_listable
    rename_index :packing_items, :index_items_on_list_and_position, :index_packing_items_on_list_and_position
  end
end
