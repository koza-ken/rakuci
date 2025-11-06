class FixSpotIdNullConstraint < ActiveRecord::Migration[7.2]
  def change
    change_column_null :schedule_spots, :spot_id, true
  end
end
