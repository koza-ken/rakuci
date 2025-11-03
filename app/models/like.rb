# == Schema Information
#
# Table name: likes
#
#  id                  :bigint           not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  card_id             :bigint           not null
#  group_membership_id :bigint           not null
#
# Indexes
#
#  index_likes_on_card_id                          (card_id)
#  index_likes_on_card_id_and_group_membership_id  (card_id,group_membership_id) UNIQUE
#  index_likes_on_group_membership_id              (group_membership_id)
#
# Foreign Keys
#
#  fk_rails_...  (card_id => cards.id)
#  fk_rails_...  (group_membership_id => group_memberships.id)
#
class Like < ApplicationRecord
  belongs_to :card
  belongs_to :group_membership

  validates :group_membership_id, uniqueness: { scope: :card_id }
end
