# == Schema Information
#
# Table name: groups
#
#  id                 :bigint           not null, primary key
#  end_date           :date
#  invite_token       :string(64)       not null
#  name               :string(30)       not null
#  start_date         :date
#  trip_memo          :text
#  trip_name          :string(50)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :integer          not null
#
# Indexes
#
#  index_groups_on_created_by_user_id  (created_by_user_id)
#  index_groups_on_invite_token        (invite_token) UNIQUE
#  index_groups_on_start_date          (start_date)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#
require "test_helper"

class GroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
