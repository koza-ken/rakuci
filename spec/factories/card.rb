FactoryBot.define do
  factory :card do
    sequence(:name) { |n| "card#{n}" }
    memo { Faker::Lorem.characters(number: 200) }

    # デフォルトはuser_idを持つ（個人用カード）
    association :user, strategy: :create
    group_id { nil }

    trait :for_user do
      # user_idを明示的に指定
      association :user, strategy: :create
    end

    trait :for_group do
      # group_idに切り替え、user_idはnil
      user_id { nil }
      association :group, strategy: :create
    end
  end
end
