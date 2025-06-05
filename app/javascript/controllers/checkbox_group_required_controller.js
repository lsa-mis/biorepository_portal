import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkbox-group-required"
export default class extends Controller {
  static targets = ["checkboxes", "form"]

  connect() {
   console.log("CheckboxGroupRequiredController connected")
  }

  submitForm(event) {
    var checkbox_error_place = document.getElementById('checkbox_error')
    checkbox_error_place.innerHTML = ''
    if (!this.checkboxesTargets.map(x => x.checked).includes(true)) {
      checkbox_error_place.innerHTML = "Please select at least one email address."
      event.preventDefault()
    }
  }
}
