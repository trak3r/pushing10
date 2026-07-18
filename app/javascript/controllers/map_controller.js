import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { flights: String }

  connect() {
    this.init()
  }

  flightsValueChanged() {
    this.init()
  }

  init() {
    if (this.timer) clearInterval(this.timer)

    const raw = this.flightsValue
    if (!raw) return

    const parsed = JSON.parse(raw)
    if (!parsed.length) return

    this.flights = parsed

    this.markers = {}
    this.element.querySelectorAll(".plane-marker").forEach(el => {
      const id = el.dataset.flightId
      if (id) this.markers[id] = el
    })

    this.legendEtas = {}
    this.element.querySelectorAll(".map-legend-item").forEach(el => {
      const id = el.dataset.flightId
      if (id) this.legendEtas[id] = el.querySelector(".legend-eta")
    })

    this.t0 = Date.now()
    this.tick()
    this.timer = setInterval(() => this.tick(), 50)
  }

  disconnect() {
    if (this.timer) clearInterval(this.timer)
  }

  tick() {
    const secs = (Date.now() - this.t0) / 1000

    for (const f of this.flights) {
      const t = Math.min(Math.max((f.elapsed + secs) / f.duration, 0), 1)
      const arrived = t >= 1

      const marker = this.markers[f.id]
      if (marker) {
        if (arrived) {
          marker.style.display = "none"
        } else {
          marker.style.display = ""
          const u = 1 - t
          const x = u * u * f.fx + 2 * u * t * f.cx + t * t * f.tx
          const y = u * u * f.fy + 2 * u * t * f.cy + t * t * f.ty
          const tx = 2 * u * (f.cx - f.fx) + 2 * t * (f.tx - f.cx)
          const ty = 2 * u * (f.cy - f.fy) + 2 * t * (f.ty - f.cy)
          const angle = Math.round(Math.atan2(ty, tx) * 180 / Math.PI + 90)
          marker.setAttribute("transform",
            `translate(${x.toFixed(1)},${y.toFixed(1)}) rotate(${angle})`)
        }
      }

      const etaEl = this.legendEtas[f.id]
      if (etaEl) {
        const left = f.duration - (f.elapsed + secs)
        if (arrived) {
          etaEl.textContent = "Arrived"
          etaEl.style.color = "#f5c842"
        } else {
          etaEl.textContent = Math.ceil(Math.max(left, 0)) + "s"
          etaEl.style.color = ""
        }
      }
    }
  }
}
