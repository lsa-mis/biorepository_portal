import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    url: String,
    turboFrame: String,
    modalTarget: String
  }

  connect() {
    // Ensure the link is properly focusable
    if (!this.element.hasAttribute('tabindex')) {
      this.element.setAttribute('tabindex', '0')
    }
  }

  click(event) {
    this.loadContent()
  }

  keydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.loadContent()
    }
  }

  loadContent() {
    const url = this.urlValue || this.element.href
    const turboFrame = this.turboFrameValue || this.element.dataset.turboFrame
    const modalTarget = this.modalTargetValue || this.element.dataset.bsTarget

    if (url && turboFrame) {
      // Make the Turbo Stream request
      fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'Turbo-Frame': turboFrame
        }
      })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.text()
      })
      .then(html => {
        // Process the turbo stream response
        Turbo.renderStreamMessage(html)
        
        // Show the modal after content is loaded
        this.showModal(modalTarget)
      })
      .catch(error => {
        console.error('Error loading modal content:', error)
      })
    }
  }

  showModal(modalSelector) {
    setTimeout(() => {
      const modalElement = document.querySelector(modalSelector)
      if (modalElement) {
        const frame = modalElement.querySelector("#modal_content_frame")
        if (frame && frame.innerHTML.trim() !== "") {
          const modal = window.bootstrap.Modal.getOrCreateInstance(modalElement)
          modal.show()
        }
      }
    }, 100)
  }
}
