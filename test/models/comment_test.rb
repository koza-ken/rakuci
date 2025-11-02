# == Schema Information
#
# Table name: comments
#
#  id                  :bigint           not null, primary key
#  content             :text             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  card_id             :bigint           not null
#  group_membership_id :bigint           not null
#
# Indexes
#
#  index_comments_on_card_id                 (card_id)
#  index_comments_on_card_id_and_created_at  (card_id,created_at)
#  index_comments_on_group_membership_id     (group_membership_id)
#
# Foreign Keys
#
#  fk_rails_...  (card_id => cards.id)
#  fk_rails_...  (group_membership_id => group_memberships.id)
#
require "test_helper"

class CommentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
