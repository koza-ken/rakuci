class Item < ApplicationRecord
  belongs_to :item_list

  # リストごとに並び順を管理するためにスコープを設定
  acts_as_list scope: :item_list

  validates :name, presence: true, length: { maximum: 100 }
end
