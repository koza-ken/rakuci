class RenameSnapshotColumnsInScheduleSpots < ActiveRecord::Migration[7.2]
  def change
    change_table :schedule_spots do |t|
      t.rename :snapshot_name, :name
      t.rename :snapshot_address, :address
      t.rename :snapshot_phone_number, :phone_number
      t.rename :snapshot_website_url, :website_url
      t.rename :snapshot_category_id, :category_id
    end
  end
end
