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
FactoryBot.define do
  factory :item do
    item_list_id { 1 }
    name { "MyString" }
    checked { false }
    position { 1 }
  end
end
