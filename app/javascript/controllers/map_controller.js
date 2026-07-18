import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const raw = this.element.dataset.mapFlights
    if (!raw) return

    this.flights = JSON.parse(raw)
    this.width = parseFloat(this.element.dataset.mapWidth)
    this.height = parseFloat(this.element.dataset.mapHeight)
    this.pad = 20

    this.minLng = Math.min(...this.flights.map(f => Math.min(f.from_lng, f.to_lng))) - 0.5
    this.maxLng = Math.max(...this.flights.map(f => Math.max(f.from_lng, f.to_lng))) + 0.5
    this.minLat = Math.min(...this.flights.map(f => Math.min(f.from_lat, f.to_lat))) - 0.5
    this.maxLat = Math.max(...this.flights.map(f => Math.max(f.from_lat, f.to_lat))) + 0.5

    this.svg = this.element.querySelector(".map-svg")
    if (!this.svg) return

    this.markers = {}
    this.element.querySelectorAll(".plane-marker").forEach(el => {
      const id = el.dataset.flightId
      if (id) this.markers[id] = el
    })

    this.startTime = Date.now()

    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    if (this.interval) clearInterval(this.interval)
  }

  projX(lng) {
    return (lng - this.minLng) / (this.maxLng - this.minLng) * this.width + this.pad
  }

  projY(lat) {
    return (this.maxLat - lat) / (this.maxLat - this.minLat) * this.height + this.pad
  }

  arcPos(fromLat, fromLng, toLat, toLng, t) {
    const x1 = this.projX(fromLng)
    const y1 = this.projY(fromLat)
    const x2 = this.projX(toLng)
    const y2 = this.projY(toLat)

    const mx = (x1 + x2) / 2
    const my = (y1 + y2) / 2
    const dx = x2 - x1
    const dy = y2 - y1
    const dist = Math.sqrt(dx * dx + dy * dy)
    const nx = -dy / dist
    const ny = dx / dist
    const arcHeight = dist * 0.4

    const cx = mx + nx * arcHeight
    const cy = my + ny * arcHeight

    const u = 1 - t
    const x = u * u * x1 + 2 * u * t * cx + t * t * x2
    const y = u * u * y1 + 2 * u * t * cy + t * t * y2

    const tx = 2 * u * (cx - x1) + 2 * t * (x2 - cx)
    const ty = 2 * u * (cy - y1) + 2 * t * (y2 - cy)
    const angle = Math.atan2(ty, tx) * 180 / Math.PI

    return { x: x.toFixed(1), y: y.toFixed(1), angle: angle.toFixed(1) }
  }

  tick() {
    const elapsed = (Date.now() - this.startTime) / 1000

    this.flights.forEach(f => {
      const elapsedSinceDeparture = elapsed + f.progress * 10
      let t = elapsedSinceDeparture / 10

      if (t > 1) {
        t = 1
        const marker = this.markers[f.id]
        if (marker) marker.style.display = "none"
        return
      }

      const pos = this.arcPos(f.from_lat, f.from_lng, f.to_lat, f.to_lng, t)
      const marker = this.markers[f.id]
      if (marker) {
        marker.setAttribute("transform", `translate(${pos.x}, ${pos.y}) rotate(${pos.angle})`)
      }
    })
  }
}
