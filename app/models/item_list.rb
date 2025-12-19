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
