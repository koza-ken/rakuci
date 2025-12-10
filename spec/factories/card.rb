FactoryBot.define do
  factory :card do
    sequence(:name) { |n| "card#{n}" }
    memo { Faker::Lorem.characters(number: 200) }

    # デフォルトは個人用カード（cardable = User）
    association :cardable, factory: :user

    trait :for_user do
      # 個人用カード（明示的に指定）
      association :cardable, factory: :user
    end

    trait :for_group do
      # グループ用カード（cardable = Group）
      association :cardable, factory: :group
    end
  end
end
