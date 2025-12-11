import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitButton"]

  connect() {
    this.setupCheckboxListeners()
    this.updateSubmitButton()
  }

  setupCheckboxListeners() {
    const checkboxes = this.getCheckboxes()

    checkboxes.forEach(checkbox => {
      checkbox.addEventListener("change", () => {
        this.updateSubmitButton()
      })
    })
  }

  getCheckboxes() {
    return this.element.querySelectorAll('input[type="checkbox"][name="spot_ids[]"]')
  }

  updateSubmitButton() {
    const checkboxes = this.getCheckboxes()
    const hasCheckedCheckbox = Array.from(checkboxes).some(checkbox => checkbox.checked)

    if (this.hasSubmitButtonTarget) {
      const button = this.submitButtonTarget

      if (hasCheckedCheckbox) {
        // 有効化
        button.removeAttribute("disabled")
        button.classList.remove("opacity-50", "cursor-not-allowed", "bg-gray-300")
        button.value = button.dataset.enableText || "選択したスポットを追加"
      } else {
        // 無効化
        button.setAttribute("disabled", "disabled")
        button.classList.add("opacity-50", "cursor-not-allowed", "bg-gray-300")
        button.value = button.dataset.disabledText || "スポットを選択してください"
      }
    }
  }
}
