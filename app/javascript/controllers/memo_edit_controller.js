import { Controller } from "@hotwired/stimulus"

// メモの表示/編集モード切り替え
export default class extends Controller {
  static targets = ["display", "form"]

  connect() {
    // 表示モードのテキストエリアの高さを調整
    const displayTextarea = this.displayTarget.querySelector("textarea")
    if (displayTextarea) {
      this.autoResizeTextarea(displayTextarea)
    }

    // 編集モードのテキストエリアに自動高さ調整を設定
    const textarea = this.formTarget.querySelector("textarea")
    if (textarea) {
      textarea.addEventListener("input", () => this.autoResizeTextarea(textarea))
    }
  }

  // テキストエリアの高さを自動調整
  autoResizeTextarea(textarea) {
    textarea.style.height = "auto"
    textarea.style.height = textarea.scrollHeight + "px"
  }

  // 編集モードが表示される時に元の値を保存
  saveOriginalValue() {
    const textarea = this.formTarget.querySelector("textarea")
    if (textarea) {
      this.originalValue = textarea.value
    }
  }

  // 表示モードと編集モードを切り替える
  toggleForm() {
    // 表示モードのdisplay属性を確認
    const isHidden = this.displayTarget.classList.contains("hidden")

    if (isHidden) {
      // 編集モードが表示中 → 表示モードに戻す（キャンセル時）
      const textarea = this.formTarget.querySelector("textarea")
      // 元の値に復元
      if (textarea && this.originalValue !== undefined) {
        textarea.value = this.originalValue
      }
      // フォームをリセット
      this.formTarget.querySelector("form").reset()
      // 表示モードに戻す
      this.displayTarget.classList.remove("hidden")
      this.formTarget.classList.add("hidden")
    } else {
      // 表示モードが表示中 → 編集モードに切り替え
      // 編集モード表示時に元の値を保存
      this.saveOriginalValue()
      this.displayTarget.classList.add("hidden")
      this.formTarget.classList.remove("hidden")
      // フォームのテキストエリアにフォーカス
      const textarea = this.formTarget.querySelector("textarea")
      textarea.focus()
      // 初期表示時の高さを調整
      this.autoResizeTextarea(textarea)
    }
  }
}
