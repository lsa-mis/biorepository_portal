import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "phone", "emailError", "phoneError", "submitButton"]

  connect() {
    console.log("Address form controller connected")
  }

  submitForm(event) {
    const validate_email = this.validateEmail()
    const validate_phone = this.validatePhone()
    if (!validate_email || !validate_phone) {
      event.preventDefault()
    }
  }

  validateEmail() {
    const email = this.emailTarget.value.trim()
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

    if (email === "") {
      this.showEmailError("Email is required")
      return false
    } else if (!emailRegex.test(email)) {
      this.showEmailError("Email format is incorrect")
      return false
    } else {
      this.hideEmailError()
      return true
    }
  }

  validatePhone() {
    const phone = this.phoneTarget.value.trim()
    const us_regex = /^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/im
    const international_regex = /^\+(?:[0-9] ?){6,14}[0-9]$/;

    const us = us_regex.test(phone)
    const international = international_regex.test(phone)
    if (!us && !international) {
      this.showPhoneError("Phone number format is incorrect")
      return false
    } else {
      this.hidePhoneError()
      return true
    }
  }

  showEmailError(message) {
    if (this.hasEmailErrorTarget) {
      this.emailErrorTarget.textContent = message
      this.emailErrorTarget.style.display = "block"
    }
    this.emailTarget.classList.add("is-invalid")
  }

  hideEmailError() {
    if (this.hasEmailErrorTarget) {
      this.emailErrorTarget.style.display = "none"
    }
    this.emailTarget.classList.remove("is-invalid")
  }

  showPhoneError(message) {
    if (this.hasPhoneErrorTarget) {
      this.phoneErrorTarget.textContent = message
      this.phoneErrorTarget.style.display = "block"
    }
    this.phoneTarget.classList.add("is-invalid")
  }

  hidePhoneError() {
    if (this.hasPhoneErrorTarget) {
      this.phoneErrorTarget.style.display = "none"
    }
    this.phoneTarget.classList.remove("is-invalid")
  }
}
