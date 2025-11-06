# == Schema Information
#
# Table name: groups
#
#  id                 :bigint           not null, primary key
#  invite_token       :string(64)       not null
#  name               :string(30)       not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :integer          not null
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
    created_by_user_id { 1 }
    name { "MyString" }
    invite_token { 1 }
    trip_name { "MyString" }
    start_date { "2025-10-15" }
    end_date { "2025-10-15" }
    trip_memo { "MyText" }
  end
end
