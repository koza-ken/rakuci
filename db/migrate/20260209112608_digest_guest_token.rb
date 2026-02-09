class DigestGuestToken < ActiveRecord::Migration[7.2]
  def up
    # 新カラム追加（SHA256 hexdigest は常に64文字）
    add_column :group_memberships, :guest_token_digest, :string, limit: 64

    # add_column 後にカラムキャッシュを更新（モデル経由でデータ変換するため必須）
    GroupMembership.reset_column_information

    # 既存の平文トークンを SHA256 digest に変換
    GroupMembership.where.not(guest_token: nil).find_each do |membership|
      membership.update_column(:guest_token_digest, Digest::SHA256.hexdigest(membership.guest_token))
    end

    # 新カラムにインデックス追加
    add_index :group_memberships, :guest_token_digest

    # 旧カラムのインデックス・カラムを削除
    remove_index :group_memberships, :guest_token
    remove_column :group_memberships, :guest_token
  end

  def down
    add_column :group_memberships, :guest_token, :string, limit: 64
    add_index :group_memberships, :guest_token
    # 注意: digest から平文への逆変換は不可能。ロールバック時は既存ゲストトークンが失われる
    remove_index :group_memberships, :guest_token_digest
    remove_column :group_memberships, :guest_token_digest
  end
end
