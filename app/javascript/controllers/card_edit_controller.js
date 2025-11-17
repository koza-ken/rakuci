import { Controller } from "@hotwired/stimulus"

// カード名の表示/編集モード切り替え
export default class extends Controller {
  static targets = ["display", "form"]

  // 編集モード開始時に元の値を保存
  saveOriginalValue() {
    const input = this.formTarget.querySelector("input[type='text']")
    if (input) {
      this.originalValue = input.value
    }
  }

  // 表示モードと編集モードを切り替える
  toggleForm() {
    // 表示モードのdisplay属性を確認
    const isHidden = this.displayTarget.classList.contains("hidden")

    if (isHidden) {
      // 編集モードが表示中 → 表示モードに戻す（キャンセル時）
      const input = this.formTarget.querySelector("input[type='text']")
      // 元の値に復元
      if (input && this.originalValue !== undefined) {
        input.value = this.originalValue
      }
      // 表示モードに戻す
      this.displayTarget.classList.remove("hidden")
      this.formTarget.classList.add("hidden")
    } else {
      // 表示モードが表示中 → 編集モードに切り替え
      // 編集モード開始時に元の値を保存
      this.saveOriginalValue()
      this.displayTarget.classList.add("hidden")
      this.formTarget.classList.remove("hidden")
      // フォームのテキストフィールドにフォーカス
      this.formTarget.querySelector("input[type='text']").focus()
    }
  }
}
