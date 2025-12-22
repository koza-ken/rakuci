import { Controller } from "@hotwired/stimulus"

// アイテム追加フォームの表示/非表示を制御
export default class extends Controller {
  static targets = ["form", "addButton", "nameInput"]

  connect() {
    // フォーム外クリックでキャンセル処理
    this.outsideClickHandler = (e) => {
      if (!this.formTarget.classList.contains("hidden") && !this.formTarget.contains(e.target) && !this.addButtonTarget.contains(e.target)) {
        this.toggleForm()
      }
    }
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    // イベントリスナーをクリーンアップ
    document.removeEventListener("click", this.outsideClickHandler)
  }

  // フォームの表示/非表示を切り替える
  toggleForm() {
    const isHidden = this.formTarget.classList.contains("hidden")

    if (isHidden) {
      // フォーム非表示状態 → 表示に切り替え
      this.formTarget.classList.remove("hidden")
      // フォームのテキストフィールドにフォーカス
      this.nameInputTarget.focus()
    } else {
      // フォーム表示状態 → 非表示に切り替え（キャンセル時）
      this.formTarget.classList.add("hidden")
      // フォームをリセット
      this.nameInputTarget.value = ""
    }
  }

}
