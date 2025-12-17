import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastScrollTop = 0
    window.addEventListener("scroll", this.handleScroll.bind(this))
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll.bind(this))
  }

  handleScroll() {
    const currentScroll = window.scrollY

    // 下にスクロール → ヘッダーを上に移動（非表示）
    if (currentScroll > this.lastScrollTop && currentScroll > 50) {
      this.element.style.transform = "translateY(-100%)"
    }
    // 上にスクロール → ヘッダーを下に移動（表示）
    else {
      this.element.style.transform = "translateY(0)"
    }

    this.lastScrollTop = currentScroll
  }
}
