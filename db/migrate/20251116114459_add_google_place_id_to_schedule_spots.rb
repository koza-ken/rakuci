class AddGooglePlaceIdToScheduleSpots < ActiveRecord::Migration[7.2]
  def change
    add_column :schedule_spots, :google_place_id, :string
  end
end
