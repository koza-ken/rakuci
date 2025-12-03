FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "テストグループ#{n}" }
    # 関連付けのuserを作成したときに保存するようstrategyオプション
    association :creator, factory: :user, strategy: :create

    trait :with_members do
      after(:create) do |group, evaluator|
        create_list(:group_membership, 3, group: group)
      end
    end
  end
end
