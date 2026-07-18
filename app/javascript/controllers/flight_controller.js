import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["countdown", "progress"]

  connect() {
    this.remaining = parseInt(this.element.dataset.flightSeconds)
    this.total = parseInt(this.element.dataset.flightTotal)
    this.planeId = this.element.dataset.flightPlaneId

    if (this.remaining <= 0) return

    this.interval = setInterval(() => {
      this.remaining--
      if (this.remaining <= 0) {
        clearInterval(this.interval)
        window.location.href = `/planes/${this.planeId}`
      } else {
        const el = document.getElementById("eta-countdown")
        if (el) el.textContent = this.remaining + "s"

        const progress = document.getElementById("eta-progress")
        if (progress) progress.value = this.total - this.remaining
      }
    }, 1000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }
}
