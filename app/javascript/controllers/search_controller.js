import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fields", "row"]
  index = 1

  addField() {
    const template = this.rowTargets[0].cloneNode(true)
    template.querySelectorAll("input, select").forEach(el => el.value = "")
    this.fieldsTarget.appendChild(template)
    this.index++
  }

  removeField(event) {
    if (this.rowTargets.length > 1) {
      event.target.closest(".search-row").remove()
    }
  }
}
// This Stimulus controller manages the dynamic addition and removal of search fields
