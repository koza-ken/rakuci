# == Schema Information
#
# Table name: item_lists
#
#  id            :bigint           not null, primary key
#  listable_type :string           not null
#  name          :string(100)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  listable_id   :integer          not null
#
# Indexes
#
#  index_item_lists_on_listable  (listable_type,listable_id) UNIQUE
#
class ItemList < ApplicationRecord
  # ポリモーフィック関連付け（User または Schedule に紐付け）
  belongs_to :listable, polymorphic: true

  # 持ち物アイテムとの関連
  has_many :items, dependent: :destroy

  # バリデーション
  validates :listable_type, presence: true, inclusion: { in: %w[User Schedule] }
  validates :listable_id, presence: true
  validates :name, length: { maximum: 100 }
end
