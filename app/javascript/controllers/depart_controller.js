import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker", "button"]

  toggle() {
    const isHidden = this.pickerTarget.style.display === "none"
    this.pickerTarget.style.display = isHidden ? "block" : "none"
    this.buttonTarget.textContent = isHidden ? "✕ Close" : "✈ Depart"
  }
}
