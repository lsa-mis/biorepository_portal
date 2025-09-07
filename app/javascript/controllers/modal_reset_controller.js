import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Hide the modal on connect (page load or Turbo render)
    if (this.element && window.bootstrap) {
      const modal = window.bootstrap.Modal.getInstance(this.element)
      if (modal) {
        modal.hide()
      }
    } else if (this.element) {
      // Fallback: force hide via class removal
      if (document.activeElement) {
        document.activeElement.blur()
      }
      // Then hide the modal safely
      this.element.classList.remove("show")
      this.element.style.display = "none"
      this.element.setAttribute("aria-hidden", "true")
    }
  }
}
