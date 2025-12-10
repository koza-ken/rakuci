import { Controller } from "@hotwired/stimulus"

// モーダルの制御
export default class extends Controller {
  // float action button
  static targets = [ "fab" ]

  // FABボタンの状態管理（モーダルを開くとき）
  setGroupId(event) {
    // FABボタンに .active クラスを付ける
    if (this.hasFabTarget) {
      this.fabTarget.classList.add("active")
    }
  }

  // 背景クリックでモーダルを閉じる
  close() {
    // Turbo Frameの中身を空にしてモーダルを非表示
    // remove()だとTurbo Frameごと削除されて2回目以降表示されなくなる
    this.element.innerHTML = ""

    // FABボタンの .active クラスを削除（全ページから探索）
    const fabButton = document.querySelector('[data-modal-target="fab"]')
    if (fabButton) {
      fabButton.classList.remove("active")
    }
  }
}
