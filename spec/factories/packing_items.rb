# == Schema Information
#
# Table name: packing_items
#
#  id              :bigint           not null, primary key
#  checked         :boolean          default(FALSE), not null
#  name            :string(100)      not null
#  position        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  packing_list_id :integer          not null
#
# Indexes
#
#  index_packing_items_on_list_and_position  (packing_list_id,position)
#  index_packing_items_on_packing_list_id    (packing_list_id)
#
# Foreign Keys
#
#  fk_rails_...  (packing_list_id => packing_lists.id)
#
FactoryBot.define do
  factory :packing_item do
    association :packing_list
    name { "持ち物アイテム" }
    checked { false }
    # position は acts_as_list が自動で管理するため設定不要
  end
end
