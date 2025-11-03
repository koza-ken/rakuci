class Like < ApplicationRecord
  belongs_to :card
  belongs_to :group_membership
end
