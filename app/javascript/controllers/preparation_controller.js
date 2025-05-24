import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["detail", "button"]

  connect() {
    this.hideAllDetails()
  }

  select(event) {
    const clickedButton = event.currentTarget
    const index = clickedButton.dataset.prepId

    // reset all other buttons
    this.buttonTargets.forEach(btn => {
      btn.classList.remove("btn-primary", "text-white")
      btn.classList.add("btn-outline-secondary")
    })

    // style clicked button
    clickedButton.classList.add("btn-primary", "text-white")
    clickedButton.classList.remove("btn-outline-secondary")

    // hides all irrelevant details
    this.hideAllDetails()

    // show the selected detail
    const detail = this.detailTargets.find(d => d.dataset.prepId === index)
    if (detail) detail.classList.remove("d-none")
  }

  hideAllDetails() {
    this.detailTargets.forEach(d => d.classList.add("d-none"))
  }
}