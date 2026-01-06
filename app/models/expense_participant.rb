# == Schema Information
#
# Table name: expense_participants
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  expense_id            :bigint           not null
#  group_membership_id   :bigint           not null
#
# Indexes
#
#  index_expense_participants_on_expense_id           (expense_id)
#  index_expense_participants_on_membership_id        (group_membership_id)
#  index_expense_participants_unique                  (expense_id,group_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (expense_id => expenses.id)
#  fk_rails_...  (group_membership_id => group_memberships.id)
#

class ExpenseParticipant < ApplicationRecord
  # アソシエーション
  belongs_to :expense
  belongs_to :group_membership

  # バリデーション
  validates :expense_id, presence: true
  validates :group_membership_id, presence: true
  validates :group_membership_id, uniqueness: { scope: :expense_id }

  # カスタムバリデーション
  validate :group_membership_belongs_to_expense_group

  private

  # group_membership（割り勘の対象者）がこの支出のグループに属しているか確認
  def group_membership_belongs_to_expense_group
    return if group_membership.blank? || expense.blank?
    unless group_membership.group_id == expense.group_id
      errors.add(:group_membership, "はこのグループに属していません")
    end
  end
end
