import { Controller } from "@hotwired/stimulus"

// モーダルの制御
export default class extends Controller {
  // float action button
  static targets = [ "fab" ]

  // FABボタンの状態管理（モーダルを開くとき）
  setGroupId() {
    // FABボタンに .active クラスを付ける
    if (this.hasFabTarget) {
      this.fabTarget.classList.add("active")
    }
  }

  // 背景クリック、キャンセルボタンクリックでモーダルを閉じる
  close(event) {
    // キャンセルボタンのクリックイベントの場合、デフォルト動作を prevent
    // (link_to のページ遷移を防ぐため)
    if (event && event.target.tagName === 'A') {
      event.preventDefault()
    }

    const form = this.element.querySelector('form')

    // フォーム内に入力値があるか判定
    if (form && this.hasFormInput(form)) {
      // 確認ダイアログ表示
      if (confirm('途中の内容は保存されませんがよろしいですか？')) {
        this.clearModal()
      }
    } else {
      // 入力なし → そのまま閉じる
      this.clearModal()
    }
  }

  // フォーム内に入力値があるか判定（値の有無のみ）
  // hidden field と submit ボタンは除外
  hasFormInput(form) {
    const inputs = form.querySelectorAll('input:not([type="hidden"]):not([type="submit"]), textarea, select')
    return Array.from(inputs).some(input => input.value.trim() !== '')
  }

  // モーダルをクリアして非表示にする
  clearModal() {
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
