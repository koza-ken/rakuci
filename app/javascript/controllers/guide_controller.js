import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "slide", "indicator", "nextButton", "startButton", "previousButton"]
  static values = { currentSlide: Number }

  connect() {
    // スライド機能が必要か判定（slide target が存在するか）
    if (this.hasSlideTargets) {
      this.initializeSlides()
    } else {
      // Turbo Stream で動的追加される場合、DOM を手動で確認して初期化
      const slideElements = this.element.querySelectorAll("[data-guide-target='slide']")
      if (slideElements.length > 0) {
        this.initializeSlides()
      } else {
        // さらに待つ必要がある場合
        setTimeout(() => {
          if (this.hasSlideTargets) {
            this.initializeSlides()
          }
        }, 100)
      }
    }
  }

  initializeSlides() {
    this.currentSlideValue = 0
    this.slideDirection = "right" // "right" = 次へ, "left" = 戻る

    // 初期状態：すべてのスライドを hidden で初期化
    this.slideTargets.forEach((slide) => {
      slide.classList.add("hidden")
    })

    this.updateDisplay()
  }

  // カードガイド用：モーダル toggle
  toggleModal() {
    this.modalTarget.classList.toggle("hidden")
    this.modalTarget.classList.toggle("flex")
    this.modalTarget.classList.toggle("items-center")
    this.modalTarget.classList.toggle("justify-center")
  }

  // チュートリアル用：モーダルを閉じて DOM から削除
  closeAndRemove() {
    this.modalTarget.remove()
  }

  // チュートリアル用：次のスライドへ
  nextSlide() {
    if (this.currentSlideValue < this.slideTargets.length - 1) {
      this.slideDirection = "right" // 次へボタン = 右から左へ
      this.currentSlideValue += 1
      this.updateDisplay()
    }
  }

  // チュートリアル用：前のスライドへ
  previousSlide() {
    if (this.currentSlideValue > 0) {
      this.slideDirection = "left" // 戻るボタン = 左から右へ
      this.currentSlideValue -= 1
      this.updateDisplay()
    }
  }

  // チュートリアル用：スライド表示更新
  updateDisplay() {
    // すべてのスライドを非表示
    this.slideTargets.forEach((slide) => {
      slide.classList.remove("opacity-100", "pointer-events-auto", "slide-in-from-right", "slide-in-from-left")
      slide.classList.add("opacity-0", "pointer-events-none", "hidden")
    })

    // 現在のスライドを表示（方向に応じたアニメーション付き）
    const currentSlide = this.slideTargets[this.currentSlideValue]
    currentSlide.classList.remove("opacity-0", "pointer-events-none", "hidden")
    currentSlide.classList.add("opacity-100", "pointer-events-auto")

    // 方向に応じたアニメーションクラスを付与
    if (this.slideDirection === "right") {
      // 次へボタン：右から左へ（右からスライドイン）
      currentSlide.classList.add("slide-in-from-right")
    } else {
      // 戻るボタン：左から右へ（左からスライドイン）
      currentSlide.classList.add("slide-in-from-left")
    }

    // インジケータを更新
    this.updateIndicators()

    // 最後のスライド判定
    this.updateButtons()
  }

  // チュートリアル用：インジケータ更新
  updateIndicators() {
    this.indicatorTargets.forEach((indicator, _index) => {
      if (_index === this.currentSlideValue) {
        indicator.classList.add("bg-secondary")
        indicator.classList.remove("bg-gray-300")
      } else {
        indicator.classList.add("bg-gray-300")
        indicator.classList.remove("bg-secondary")
      }
    })
  }

  // チュートリアル用：ボタン表示更新
  updateButtons() {
    const isFirstSlide = this.currentSlideValue === 0
    const isLastSlide = this.currentSlideValue === this.slideTargets.length - 1

    // 戻るボタン制御（最初のスライドで無効化）
    if (isFirstSlide) {
      this.previousButtonTarget.disabled = true
      this.previousButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
    } else {
      this.previousButtonTarget.disabled = false
      this.previousButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
    }

    // 次へボタン制御（最後のスライドで無効化）
    if (isLastSlide) {
      this.nextButtonTarget.disabled = true
      this.nextButtonTarget.classList.add("opacity-50", "cursor-not-allowed")
      // 「RakuCiをつかう」ボタンはいったんコメントアウト
      // if (this.hasStartButtonTarget) {
      //   this.startButtonTarget.classList.remove("hidden")
      // }
    } else {
      this.nextButtonTarget.disabled = false
      this.nextButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      // if (this.hasStartButtonTarget) {
      //   this.startButtonTarget.classList.add("hidden")
      // }
    }
  }
}
