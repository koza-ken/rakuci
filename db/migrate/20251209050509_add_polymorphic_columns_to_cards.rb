class AddPolymorphicColumnsToCards < ActiveRecord::Migration[7.2]
  def change
    # 新しいポリモーフィックカラムを追加（まだNULL許可）
    add_column :cards, :cardable_type, :string
    add_column :cards, :cardable_id, :bigint

    # インデックス追加（パフォーマンス向上）
    add_index :cards, [:cardable_type, :cardable_id]
  end
end
