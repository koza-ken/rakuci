# == Schema Information
#
# Table name: items
#
#  id           :bigint           not null, primary key
#  checked      :boolean          default(FALSE), not null
#  name         :string(100)      not null
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  item_list_id :integer          not null
#
# Indexes
#
#  index_items_on_item_list_id       (item_list_id)
#  index_items_on_list_and_position  (item_list_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (item_list_id => item_lists.id)
#
class Item < ApplicationRecord
  belongs_to :item_list

  # リストごとに並び順を管理するためにスコープを設定
  acts_as_list scope: :item_list

  validates :name, presence: true, length: { maximum: 100 }
end
