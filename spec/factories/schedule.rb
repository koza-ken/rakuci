FactoryBot.define do
  factory :schedule do
    sequence(:name) { |n| "schedule#{n}" }
    start_date { Date.current }
    end_date { Date.current + 7.days }
    memo { "Test memo" }

    # デフォルトは User のスケジュール（個人用）
    association :schedulable, factory: :user, strategy: :create

    trait :for_user do
      association :schedulable, factory: :user, strategy: :create
    end

    trait :for_group do
      association :schedulable, factory: :group, strategy: :create
    end
  end
end
