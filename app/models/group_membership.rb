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

  # グループ内でのニックネーム
  def nickname
    group_nickname
  end

  # ゲストトークンの生成
  def generate_guest_token
    self.guest_token ||= SecureRandom.urlsafe_base64(32)
  end

  # メンバーシップが指定されたユーザーによって削除可能かを判定
  def deletable_by?(user)
    group.created_by?(user) && !owner?
  end

  # ログインユーザーがグループのメンバーか確認
  def self.user_member?(user, group)
    exists?(user: user, group: group)
  end

  # ゲストトークンがグループのメンバーか確認
  def self.guest_member?(guest_token, group_or_group_id)
    return false if guest_token.blank?
    scope = where(guest_token: guest_token)
    # group_or_group_idがGroupのインスタンスの場合
    if group_or_group_id.is_a?(Group)
      scope.exists?(group: group_or_group_id)
    # group_idの場合
    else
      scope.exists?(group_id: group_or_group_id)
    end
  end

  private

  def must_have_user_or_guest_token
    if user_id.blank? && guest_token.blank?
      errors.add(:base, "ユーザーまたはゲストトークンのどちらかが必要です")
    end
  end
end
