import { Controller } from "@hotwired/stimulus"

// Turboのグローバルイベントを管理するコントローラー
// body要素に data-controller="turbo" を追加して使用
export default class extends Controller {
  connect() {
    // Turboがページをキャッシュする前にflashメッセージを削除
    // ブラウザバック時に古いflashメッセージが再表示されることを防ぐ
    document.addEventListener("turbo:before-cache", this.clearFlash)
  }

  disconnect() {
    // クリーンアップ：イベントリスナーを削除
    document.removeEventListener("turbo:before-cache", this.clearFlash)
  }

  // flashメッセージコンテナをクリア
  clearFlash = () => {
    const flashContainer = document.getElementById("flash-container")
    if (flashContainer) {
      flashContainer.innerHTML = ""
    }
  }
}
