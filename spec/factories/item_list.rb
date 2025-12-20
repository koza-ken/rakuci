FactoryBot.define do
  factory :item_list do
    association :listable, factory: :user
    name { "旅行持ち物リスト" }

    trait :for_schedule do
      association :listable, factory: :schedule
    end
  end
end
