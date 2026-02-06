# == Schema Information
#
# Table name: group_memberships
#
#  id             :bigint           not null, primary key
#  group_nickname :string(20)
#  guest_token    :string(64)
#  role           :string           default("member"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  group_id       :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_group_memberships_on_group_id                     (group_id)
#  index_group_memberships_on_group_id_and_group_nickname  (group_id,group_nickname) UNIQUE
#  index_group_memberships_on_guest_token                  (guest_token)
#  index_group_memberships_on_user_id                      (user_id)
#  index_group_memberships_on_user_id_and_group_id         (user_id,group_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (user_id => users.id)
#
class GroupMembership < ApplicationRecord
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_cards, through: :likes, source: :card
  has_many :expenses, foreign_key: "paid_by_membership_id", dependent: :nullify, inverse_of: :paid_by_membership
  has_many :expense_participants, dependent: :destroy
  has_many :joined_expenses, through: :expense_participants, source: :expense
  belongs_to :user, optional: true
  belongs_to :group, touch: true
  validates :group_nickname, presence: true, uniqueness: { scope: :group_id }, length: { maximum: 20 }
  validates :guest_token, length: { maximum: 64 }, allow_blank: true
  # user_id または guest_token のどちらかが必須
  validate :must_have_user_or_guest_token

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

  # ゲストトークンの生成
  def generate_guest_token
    self.guest_token ||= SecureRandom.urlsafe_base64(32)
  end

  # ユーザーまたはゲストトークンをメンバーシップに紐づける
  # ゲスト参加の場合はトークンを返す、ログイン済みなら nil を返す、失敗時は false
  def attach_user_or_guest_token(current_user)
    if current_user&.id
      update(user_id: current_user.id) ? nil : false
    else
      generate_guest_token
      save ? guest_token : false
    end
  end

  # メンバーシップが指定されたユーザーによって削除可能かを判定
  def deletable_by?(user)
    group.created_by?(user) && !owner?
  end

  # ゲストトークンでグループのメンバーか確認
  def self.guest_member_by_token?(guest_token, group)
    return false if guest_token.blank?
    exists?(guest_token: guest_token, group: group)
  end

  private

  # カスタムバリデーション
  def must_have_user_or_guest_token
    if user_id.blank? && guest_token.blank?
      errors.add(:base, "ユーザーまたはゲストトークンのどちらかが必要です")
    end
  end
end
