import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("RemoteModalController connected")
    // Use global bootstrap object loaded via CDN
    this.modal = new window.bootstrap.Modal(this.element)
  }

  hideBeforeRender(event) {
    if (this.isOpen()) {
      event.preventDefault()
      this.element.addEventListener('hidden.bs.modal', event.detail.resume)
      this.modal.hide()
    }
  }

  isOpen() {
    return this.element.classList.contains("show")
  }

  showAfterRender(event) {
    const frame = this.element.querySelector("#modal_content_frame")
    if (frame && frame.innerHTML.trim() !== "") {
      this.modal?.show()
    }
  }

  hide(event) {
    console.log("RemoteModalController HIDE connected")
    if (event.detail.success) {
      this.manualHide()
    }
  }

  manualHide() {
    this.modal.hide()
  }
}
