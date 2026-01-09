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

FactoryBot.define do
  factory :expense do
    association :group, strategy: :create
    association :paid_by_membership, factory: :group_membership, strategy: :create
    sequence(:name) { |n| "テスト支出#{n}" }
    amount { 1000 }
    paid_at { Date.current }
    memo { nil }

    transient do
      expense_participants_list { nil }
    end

    after(:build) do |expense, evaluator|
      # validation チェック用に in-memory の participants を設定
      memberships = evaluator.expense_participants_list || [expense.paid_by_membership]
      memberships.each do |membership|
        expense.expense_participants.build(group_membership: membership)
      end
    end

    after(:create) do |expense, evaluator|
      # DB に participants を作成（build で既に participants は in-memory に存在）
      memberships = evaluator.expense_participants_list || [expense.paid_by_membership]

      # 既存の expense_participants を削除
      expense.expense_participants.destroy_all

      # 新しく participants を作成
      memberships.each do |membership|
        expense.expense_participants.create!(group_membership: membership)
      end
    end
  end
end
