FactoryBot.define do
  factory :group_membership do
    association :user, strategy: :create
    association :group, strategy: :create
    role { "member" }
    group_nickname { "DefaultNickname" }

    trait :owner do
      role { "owner" }
    end

    trait :guest do
      user { nil }
      sequence(:guest_token) { |n| "guest_token_#{n}" }
    end
  end
end
