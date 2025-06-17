import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  connect() {
    console.log("RemoteModalController connected")
    this.modal = new Modal(this.element)
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
    const modalEl = this.element
    modalEl.classList.remove("show")
    modalEl.setAttribute("aria-hidden", "true")
    modalEl.style.display = "none"

    const backdrop = document.querySelector(".modal-backdrop")
    if (backdrop) backdrop.remove()

    document.body.classList.remove("modal-open")
    document.body.style = ""
  }
}
