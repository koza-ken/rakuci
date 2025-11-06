class CreateSchedules < ActiveRecord::Migration[7.2]
  def change
    create_table :schedules do |t|
      t.string :schedluable_type
      t.bigint :schedulable_id
      t.string :name
      t.date :start_date
      t.date :end_date
      t.text :memo

      t.timestamps
    end
  end
end
