import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkbox-group-required"
export default class extends Controller {
  static targets = ["hiddenField", "error", "hiddenContainer"]

  connect() {
    console.log("CheckboxGroupRequiredController connected")
    console.log("Hidden fields found:", this.hiddenFieldTargets.length)
  }

  validateAndSubmit(event) {
    console.log("Form submission intercepted")
    console.log("Hidden fields at submission:", this.hiddenFieldTargets.length)
    
    // Clear previous error
    if (this.hasErrorTarget) {
      this.errorTarget.innerHTML = ''
    }
    
    // Check if any hidden fields exist (meaning emails are selected)
    if (this.hiddenFieldTargets.length === 0) {
      console.log("No hidden fields found - preventing submission")
      if (this.hasErrorTarget) {
        this.errorTarget.innerHTML = "Please select at least one email address."
      }
      event.preventDefault()
      return false
    }
    
    console.log("Validation passed - allowing form submission")
    return true
  }
}