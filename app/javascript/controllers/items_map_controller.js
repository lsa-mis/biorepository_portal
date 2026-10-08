import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Connects to data-controller="items-map"
export default class extends Controller {
  static values = { url: String }

  async connect() {
    this.map = L.map(this.element, { preferCanvas: true }).setView([20, 0], 2)

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 18,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
    if (!response.ok || !this.map) return
    const points = await response.json()

    const layer = L.featureGroup()
    points.forEach(([id, lat, lng, catalogNumber, division]) => {
      L.circleMarker([lat, lng], { radius: 4, weight: 1, fillOpacity: 0.7 })
        .bindPopup(() => this.popupContent(id, catalogNumber, division))
        .addTo(layer)
    })
    layer.addTo(this.map)
    if (points.length) this.map.fitBounds(layer.getBounds(), { padding: [20, 20] })
  }

  disconnect() {
    this.map?.remove()
    this.map = null
  }

  // Built with DOM nodes so catalog numbers and division names are not parsed as HTML
  popupContent(id, catalogNumber, division) {
    const container = document.createElement("div")
    const link = document.createElement("a")
    link.href = `/items/${id}`
    link.textContent = catalogNumber || `Item ${id}`
    container.append(link, document.createElement("br"), division || "")
    return container
  }
}
