class RemoveUniqueIndexFromScheduleSpots < ActiveRecord::Migration[7.2]
  def change
    remove_index :schedule_spots, name: :index_ss_on_schedule_and_position
  end
end
