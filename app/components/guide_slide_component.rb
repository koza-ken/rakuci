class GuideSlideComponent < ViewComponent::Base
  # ガイドの1つのスライドを表示するコンポーネント
  # スライド表示・非表示の切り替え機能は Stimulus の guide_controller が担当
  def initialize(slide_number:)
    @slide_number = slide_number
  end

  def slide_data
    {
      title_key: "cards.index_content.guide_slide_#{@slide_number}_title",
      description_key: "cards.index_content.guide_slide_#{@slide_number}_description",
      image: "guide_slide_#{@slide_number}.svg"
    }
  end
end
