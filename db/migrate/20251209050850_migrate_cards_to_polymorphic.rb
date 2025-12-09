class MigrateCardsToPolymorphic < ActiveRecord::Migration[7.2]
  def up
    # 個人用カード（user_idがある）をポリモーフィックに移行
    execute <<-SQL
      UPDATE cards
      SET cardable_type = 'User',
          cardable_id = user_id
      WHERE user_id IS NOT NULL
    SQL

    # グループ用カード（group_idがある）をポリモーフィックに移行
    execute <<-SQL
      UPDATE cards
      SET cardable_type = 'Group',
          cardable_id = group_id
      WHERE group_id IS NOT NULL
    SQL

    # データ移行が正しく行われたか確認
    null_count = execute("SELECT COUNT(*) FROM cards WHERE cardable_type IS NULL").first["count"].to_i
    if null_count > 0
      raise "データ移行に失敗しました: cardable_typeがNULLのレコードが#{null_count}件存在します"
    end
  end

  def down
    # ロールバック処理：ポリモーフィックカラムから元のカラムに戻す
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

    # cardable カラムをクリア
    execute <<-SQL
      UPDATE cards
      SET cardable_type = NULL,
          cardable_id = NULL
    SQL
  end
end
