# cardable ポリモーフィック関連（has_many :cards, as: :cardable）を持つモデルの共通振る舞い
module Cardable
  extend ActiveSupport::Concern

  # カードとスポットをカテゴリ毎にグルーピング（ビュー用）
  def cards_with_spots_grouped
    cards.includes(:spots).map { |card| [ card, card.spots.group_by(&:category_id) ] }
  end
end
