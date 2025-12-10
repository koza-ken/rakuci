FactoryBot.define do
  factory :comment do
    content { Faker::Lorem.characters(number: 100) }
    association :card
    association :group_membership
  end
end
