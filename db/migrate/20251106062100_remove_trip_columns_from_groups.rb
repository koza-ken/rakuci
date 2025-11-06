class RemoveTripColumnsFromGroups < ActiveRecord::Migration[7.2]
  def change
    # Group テーブルから trip_* カラムを削除
    remove_column :groups, :trip_name
    remove_column :groups, :start_date
    remove_column :groups, :end_date
    remove_column :groups, :trip_memo

  end
end
