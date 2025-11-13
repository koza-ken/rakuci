import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "deleteMode"]

  toggleDelete(event) {
    event.preventDefault()
    this.displayTarget.classList.toggle("hidden")
    this.deleteModeTarget.classList.toggle("hidden")
  }
}
