# == Schema Information
#
# Table name: group_memberships
#
#  id                 :bigint           not null, primary key
#  group_nickname     :string(20)
#  guest_token_digest :string(64)
#  role               :string           default("member"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  group_id           :bigint           not null
#  user_id            :bigint
#
# Indexes
#
#  index_group_memberships_on_group_id                     (group_id)
#  index_group_memberships_on_group_id_and_group_nickname  (group_id,group_nickname) UNIQUE
#  index_group_memberships_on_guest_token_digest           (guest_token_digest)
#  index_group_memberships_on_user_id                      (user_id)
#  index_group_memberships_on_user_id_and_group_id         (user_id,group_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (user_id => users.id)
#
class GroupMembership < ApplicationRecord
  attr_accessor :raw_guest_token # 平文トークンの一時保持用（DBには保存しない）

  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_cards, through: :likes, source: :card
  has_many :expenses, foreign_key: "paid_by_membership_id", dependent: :nullify, inverse_of: :paid_by_membership
  has_many :expense_participants, dependent: :destroy
  has_many :joined_expenses, through: :expense_participants, source: :expense
  belongs_to :user, optional: true
  belongs_to :group, touch: true
  validates :group_nickname, presence: true, uniqueness: { scope: :group_id }, length: { maximum: 20 }
  validates :guest_token_digest, length: { maximum: 64 }, allow_blank: true
  # user_id または guest_token_digest のどちらかが必須
  validate :must_have_user_or_guest_token_digest

  enum :role, { member: "member", owner: "owner" }

  # スコープ
  scope :guests, -> { where(user_id: nil) }

  # ゲストメンバーか判定
  def guest?
    user_id.nil?
  end

  # グループ内でのニックネーム
  def nickname
    group_nickname
  end

  # ゲストトークンの新規生成（digest未設定時のみ）
  def generate_guest_token
    return if guest_token_digest.present?
    self.raw_guest_token = SecureRandom.urlsafe_base64(32)
    self.guest_token_digest = self.class.digest(raw_guest_token)
    raw_guest_token
  end

  # ゲストトークンの再生成（既存トークンを上書き）
  def regenerate_guest_token
    self.raw_guest_token = SecureRandom.urlsafe_base64(32)
    self.guest_token_digest = self.class.digest(raw_guest_token)
    raw_guest_token
  end

  # ユーザーまたはゲストトークンをメンバーシップに紐づける
  # ゲスト参加の場合は平文トークンを返す、ログイン済みなら nil を返す、失敗時は false
  def attach_user_or_guest_token(current_user)
    if current_user&.id
      update(user_id: current_user.id) ? nil : false
    else
      token = guest_token_digest.present? ? regenerate_guest_token : generate_guest_token
      save ? token : false
    end
  end

  # メンバーシップが指定されたユーザーによって削除可能かを判定
  def deletable_by?(user)
    group.created_by?(user) && !owner?
  end

  # ゲストトークンでグループのメンバーか確認
  def self.guest_member_by_token?(raw_token, group)
    return false if raw_token.blank?
    exists?(guest_token_digest: digest(raw_token), group: group)
  end

  # 平文トークンから SHA256 digest を生成
  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end

  # 平文トークンから membership を検索
  def self.find_by_raw_token(raw_token, group_id:)
    return nil if raw_token.blank?
    find_by(guest_token_digest: digest(raw_token), group_id: group_id)
  end

  private

  # カスタムバリデーション
  def must_have_user_or_guest_token_digest
    if user_id.blank? && guest_token_digest.blank?
      errors.add(:base, "ユーザーまたはゲストトークンのどちらかが必要です")
    end
  end
end
