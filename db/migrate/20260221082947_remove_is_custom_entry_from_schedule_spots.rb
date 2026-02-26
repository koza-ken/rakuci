class RemoveIsCustomEntryFromScheduleSpots < ActiveRecord::Migration[7.2]
  def change
    remove_column :schedule_spots, :is_custom_entry, :boolean, default: false, null: false
  end
end
