import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Connects to data-controller="items-map"
export default class extends Controller {
  static values = { url: String, searchUrl: String }

  async connect() {
    this.map = L.map(this.element, { preferCanvas: true }).setView([20, 0], 2)

    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 18,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    // Aborted in disconnect(), so a response that arrives after the map is removed is never drawn
    this.abortController = new AbortController()
    let locations
    try {
      const response = await fetch(this.urlValue, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal
      })
      if (!response.ok) return
      locations = await response.json()
    } catch (error) {
      if (error.name === "AbortError") return
      throw error
    }

    // One marker per location; larger markers for locations with more items
    const layer = L.featureGroup()
    locations.forEach(([lat, lng, count, itemId]) => {
      L.circleMarker([lat, lng], { radius: 4 + 2 * Math.log10(count), weight: 1, fillOpacity: 0.7 })
        .bindPopup(() => this.popupContent(lat, lng, count, itemId))
        .addTo(layer)
    })
    layer.addTo(this.map)
    if (locations.length) this.map.fitBounds(layer.getBounds(), { padding: [20, 20] })
  }

  disconnect() {
    this.abortController?.abort()
    this.map?.remove()
    this.map = null
  }

  // Links to the item, or to the search results at this location when it has more than one item
  popupContent(lat, lng, count, itemId) {
    const container = document.createElement("div")
    const link = document.createElement("a")
    link.href = count === 1 ? `/items/${itemId}` : this.locationSearchUrl(lat, lng)
    link.textContent = count === 1 ? "View item" : `${count.toLocaleString()} items`
    container.append(link, document.createElement("br"), `${lat}, ${lng}`)
    return container
  }

  // The current search (if any) narrowed to items at these coordinates
  locationSearchUrl(lat, lng) {
    const url = new URL(this.searchUrlValue, window.location.origin)
    url.searchParams.set("q[decimal_latitude_eq]", lat)
    url.searchParams.set("q[decimal_longitude_eq]", lng)
    return url.pathname + url.search
  }
}
