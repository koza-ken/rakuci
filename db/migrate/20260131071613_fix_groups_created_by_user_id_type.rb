class FixGroupsCreatedByUserIdType < ActiveRecord::Migration[7.2]
  def change
    # created_by_user_id を integer から bigint に変更（親テーブルの User.id と型を統一）
    change_column :groups, :created_by_user_id, :bigint
  end
end
