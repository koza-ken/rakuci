FactoryBot.define do
  factory :like do
    association :card, strategy: :create
    association :group_membership, strategy: :create
  end
end
