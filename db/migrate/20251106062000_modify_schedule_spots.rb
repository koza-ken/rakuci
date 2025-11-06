class ModifyScheduleSpots < ActiveRecord::Migration[7.2]
  def change
    # 古いインデックス削除
    remove_index :schedule_spots, name: 'index_ss_on_schedulable_and_position'
    remove_index :schedule_spots, name: 'index_ss_on_schedulable_and_day'

    # 古いカラム削除
    remove_column :schedule_spots, :schedulable_type
    remove_column :schedule_spots, :schedulable_id

    # 新しいカラム追加
    add_column :schedule_spots, :schedule_id, :bigint, null: false

    # 外部キー追加
    add_foreign_key :schedule_spots, :schedules

    # 新しいインデックス追加
    add_index :schedule_spots, [:schedule_id, :global_position], unique: true, name: 'index_ss_on_schedule_and_position'
    add_index :schedule_spots, [:schedule_id, :day_number], name: 'index_ss_on_schedule_and_day'
  end
end
