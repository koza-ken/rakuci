FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "category#{n}" }
    sequence(:display_order) { |n| n }
  end
end
