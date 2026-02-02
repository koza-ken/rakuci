module CardsHelper
  # カテゴリ別のスポット件数を取得（ビュー用）
  def spots_count_for_category(spots_by_category, category)
    spots_by_category[category.id]&.size || 0
  end
end
