import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'sidebar' ]
  
  connect() {
    console.log("connect autosubmit")
  }

  submit() {
    Turbo.navigator.submitForm(this.formTarget)
  }

  toggle() {
    this.sidebarTarget.classList.toggle('-translate-x-full')
  }
}
