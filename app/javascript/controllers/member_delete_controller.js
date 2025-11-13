import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "deleteMode"]

  toggleDelete(event) {
    event.preventDefault()
    this.displayTarget.classList.toggle("hidden")
    this.deleteModeTarget.classList.toggle("hidden")
  }

  cancelDelete(event) {
    event.preventDefault()
    // テキストエリアの内容を更新（削除されたメンバーを反映）
    const memberList = Array.from(document.querySelectorAll("#members-list span.text-sm")).map(el => el.textContent)
    const textarea = document.getElementById("members-textarea-content")
    if (textarea) {
      textarea.value = memberList.join("\n")
    }
    // 表示モードに戻す
    this.displayTarget.classList.remove("hidden")
    this.deleteModeTarget.classList.add("hidden")
  }
}
