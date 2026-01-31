# == Schema Information
#
# Table name: groups
#
#  id                 :bigint           not null, primary key
#  invite_token       :string(64)       not null
#  name               :string(30)       not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint           not null
#
# Indexes
#
#  index_groups_on_created_by_user_id  (created_by_user_id)
#  index_groups_on_invite_token        (invite_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#
FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "テストグループ#{n}" }
    # 関連付けのuserを作成したときに保存するようstrategyオプション
    association :creator, factory: :user, strategy: :create

    trait :with_members do
      after(:create) do |group|
        FactoryBot.create_list(:group_membership, 3, group: group)
      end
    end
  end
end
