class CreateSchedules < ActiveRecord::Migration[7.2]
  def change
    create_table :schedules do |t|
      t.string :schedulable_type, null: false
      t.bigint :schedulable_id, null: false
      t.string :name, null: false
      t.date :start_date
      t.date :end_date
      t.text :memo
      t.timestamps
    end
    add_index :schedules, [:schedulable_type, :schedulable_id], unique: true, name: 'index_schedules_on_polymorphic'
  end
end
