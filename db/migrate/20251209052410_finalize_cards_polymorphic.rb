class FinalizeCardsPolymorphic < ActiveRecord::Migration[7.2]
  def up
    # NOT NULL制約を追加
    change_column_null :cards, :cardable_type, false
    change_column_null :cards, :cardable_id, false

    # 古い CHECK 制約を削除
    remove_check_constraint :cards, name: "cards_must_belong_to_user_or_group"

    # 外部キー削除
    remove_foreign_key :cards, :users
    remove_foreign_key :cards, :groups

    # インデックス削除
    remove_index :cards, :user_id
    remove_index :cards, :group_id

    # 古いカラムを削除
    remove_column :cards, :user_id
    remove_column :cards, :group_id
  end

  def down
    # ロールバック用（カラムを元に戻す）
    add_column :cards, :user_id, :bigint
    add_column :cards, :group_id, :bigint

    add_index :cards, :user_id
    add_index :cards, :group_id

    add_foreign_key :cards, :users
    add_foreign_key :cards, :groups

    # データを戻す
    execute <<-SQL
      UPDATE cards
      SET user_id = cardable_id
      WHERE cardable_type = 'User'
    SQL

    execute <<-SQL
      UPDATE cards
      SET group_id = cardable_id
      WHERE cardable_type = 'Group'
    SQL

    # CHECK制約を戻す
    add_check_constraint :cards,
      "user_id IS NOT NULL AND group_id IS NULL OR user_id IS NULL AND group_id IS NOT NULL",
      name: "cards_must_belong_to_user_or_group"

    # NOT NULL制約を解除
    change_column_null :cards, :cardable_type, true
    change_column_null :cards, :cardable_id, true
  end
end
