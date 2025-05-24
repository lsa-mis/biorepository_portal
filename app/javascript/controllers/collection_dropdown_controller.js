import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  handleChange(event) {
    const value = event.target.value
    if (value && value.startsWith("/")) {
      window.location.href = value
    } else {
      console.error("Invalid collection path:", value)
    }
  }
}