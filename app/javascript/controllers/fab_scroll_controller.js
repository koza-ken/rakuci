import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastScrollTop = 0
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll)
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  // connect,disconnectのイベントで呼び出す
  handleScroll() {
    // 現在のスクロール位置を取得
    const currentScroll = window.scrollY

    if (currentScroll > this.lastScrollTop && currentScroll > 50) {
      this.element.style.opacity = "0"
      this.element.style.pointerEvents = "none"  //opacityで透明にしただけでは要素は残るのでクリックを無効化しておく
    } else {
      this.element.style.opacity = "1"
      this.element.style.pointerEvents = ""
    }

    this.lastScrollTop = currentScroll  // 今回のスクロール位置を保存して、次回の呼び出しで参照する
  }
}
