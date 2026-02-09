# == Schema Information
#
# Table name: group_memberships
#
#  id             :bigint           not null, primary key
#  group_nickname :string(20)
#  guest_token    :string(64)
#  role           :string           default("member"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  group_id       :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_group_memberships_on_group_id                     (group_id)
#  index_group_memberships_on_group_id_and_group_nickname  (group_id,group_nickname) UNIQUE
#  index_group_memberships_on_guest_token                  (guest_token)
#  index_group_memberships_on_user_id                      (user_id)
#  index_group_memberships_on_user_id_and_group_id         (user_id,group_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :group_membership do
    association :user, strategy: :create
    association :group, strategy: :create
    role { "member" }
    sequence(:group_nickname) { |n| "ニックネーム#{n}" }

    trait :owner do
      role { "owner" }
    end

    trait :guest do
      user { nil }
      sequence(:guest_token_digest) { |n| Digest::SHA256.hexdigest("guest_token_#{n}") }
    end
  end
end
