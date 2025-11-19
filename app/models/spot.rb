# == Schema Information
#
# Table name: spots
#
#  id              :bigint           not null, primary key
#  address         :text
#  name            :string(50)       not null
#  phone_number    :string(20)
#  website_url     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  card_id         :bigint           not null
#  category_id     :bigint           not null
#  google_place_id :string
#
# Indexes
#
#  index_spots_on_card_id                      (card_id)
#  index_spots_on_card_id_and_google_place_id  (card_id,google_place_id) UNIQUE WHERE (google_place_id IS NOT NULL)
#  index_spots_on_category_id                  (category_id)
#
# Foreign Keys
#
#  fk_rails_...  (card_id => cards.id)
#  fk_rails_...  (category_id => categories.id)
#
class Spot < ApplicationRecord
  has_many :schedule_spots, dependent: :nullify
  belongs_to :card, touch: true
  belongs_to :category

  validates :name, presence: true, length: { maximum: 50 }
  validates :phone_number, length: { maximum: 20 }, allow_blank: true
  validates :google_place_id, uniqueness: { scope: :card_id }, allow_blank: true
end
