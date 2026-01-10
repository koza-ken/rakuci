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
#  index_expense_participants_on_expense_id             (expense_id)
#  index_expense_participants_on_group_membership_id    (group_membership_id)
#  index_expense_participants_on_ids                    (expense_id,group_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (expense_id => expenses.id)
#  fk_rails_...  (group_membership_id => group_memberships.id)
#

FactoryBot.define do
  factory :expense_participant do
    association :expense, strategy: :create
    association :group_membership, strategy: :create
  end
end
