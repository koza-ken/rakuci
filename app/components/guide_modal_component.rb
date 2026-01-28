class GuideModalComponent < ViewComponent::Base
  # ガイドモーダル全体を管理するコンポーネント
  # 複数のスライド（GuideSlideComponent）を統合して表示する
  SLIDE_COUNT = 5

  def slides
    (1..SLIDE_COUNT).to_a
  end
end
