class FixSchedulesUniqueIndex < ActiveRecord::Migration[7.2]
  def change
     # 既存のユニークインデックスを削除
      remove_index :schedules, name: "index_schedules_on_polymorphic"

      # Group の場合のみユニーク制約を持つ部分インデックスを追加
      add_index :schedules, [:schedulable_type, :schedulable_id],
                unique: true,
                where: "schedulable_type = 'Group'",
                name: "index_schedules_on_polymorphic"
  end
end
