# == Schema Information
#
# Table name: expenses
#
#  id                    :bigint           not null, primary key
#  amount                :integer          not null
#  memo                  :text
#  name                  :string(100)      not null
#  paid_at               :date             not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  group_id              :bigint           not null
#  paid_by_membership_id :bigint           not null
#
# Indexes
#
#  index_expenses_on_group_id               (group_id)
#  index_expenses_on_paid_by_membership_id  (paid_by_membership_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (paid_by_membership_id => group_memberships.id)
#

class Expense < ApplicationRecord
  # アソシエーション
  belongs_to :group
  belongs_to :paid_by_membership, class_name: "GroupMembership"
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :group_membership

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :paid_at, presence: true
  validates :memo, length: { maximum: 1000 }, allow_blank: true

  # カスタムバリデーション
  validate :paid_by_membership_belongs_to_group
  validate :participants_must_exist, on: :create

  # スコープ
  scope :ordered_by_paid_at, -> { order(paid_at: :desc) }

  # 指定されたメンバーシップがこの支出を支払った人か判定
  def paid_by?(membership)
    membership && paid_by_membership_id == membership.id
  end

  private

  # paid_by_membership（立替える人）がグループに属しているか確認
  def paid_by_membership_belongs_to_group
    return if paid_by_membership.blank?
    unless paid_by_membership.group_id == group_id
      errors.add(:paid_by_membership, "はこのグループに属していません")
    end
  end

  # 対象者が選択されているか確認
  def participants_must_exist
    if expense_participants.empty?
      errors.add(:base, "対象者を選択してください")
    end
  end
end
