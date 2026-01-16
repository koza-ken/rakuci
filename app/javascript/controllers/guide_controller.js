import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  toggleModal() {
    this.modalTarget.classList.toggle("hidden")
    this.modalTarget.classList.toggle("flex")
    this.modalTarget.classList.toggle("items-center")
    this.modalTarget.classList.toggle("justify-center")
  }
}
