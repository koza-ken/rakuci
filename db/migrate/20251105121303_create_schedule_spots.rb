class CreateScheduleSpots < ActiveRecord::Migration[7.2]
  def change
    create_table :schedule_spots do |t|
      t.string :schedulable_type, null: false
      t.bigint :schedulable_id, null: false
      t.references :spot, foreign_key: true
      t.integer :global_position, null: false
      t.integer :day_number, null: false
      t.time :start_time
      t.time :end_time
      t.boolean :is_custom_entry, null: false, default: false
      t.string :snapshot_name
      t.integer :snapshot_category_id
      t.string :snapshot_address
      t.string :snapshot_phone_number
      t.string :snapshot_website_url
      t.text :memo
      t.timestamps
    end
    # 同じスケジュール内でスケジュール番号（global_position）が一意になるように
    add_index :schedule_spots, [:schedulable_type, :schedulable_id, :global_position], unique: true, name: 'index_ss_on_schedulable_and_position'
    add_index :schedule_spots, [:schedulable_type, :schedulable_id, :day_number], name: 'index_ss_on_schedulable_and_day'
  end
end
