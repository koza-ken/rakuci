import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "hamburger", "overlay", "menu" ]

  connect() {
    // Turboのキャッシュ前にメニューを閉じる
    document.addEventListener("turbo:before-cache", this.close.bind(this))
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.close.bind(this))
  }

  toggle() {
    this.hamburgerTarget.classList.toggle("open");
    this.overlayTarget.classList.toggle("hidden");
    this.menuTarget.classList.toggle("translate-x-full");
    document.body.classList.toggle("overflow-hidden");
  }

  close() {
    // メニューが開いている場合のみ閉じる
    if (!this.menuTarget.classList.contains("translate-x-full")) {
      this.hamburgerTarget.classList.remove("open");
      this.overlayTarget.classList.add("hidden");
      this.menuTarget.classList.add("translate-x-full");
      document.body.classList.remove("overflow-hidden");
    }
  }
}
