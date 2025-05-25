import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="options"
export default class extends Controller {
  static targets = ["fields", "template"];
  
  connect() {
    console.log("Options controller connected");
  }

  append() {
    this.fieldsTarget.insertAdjacentHTML("beforeend", this.#templateContent);
  }

  // private

  get #templateContent() {
    return this.templateTarget.innerHTML.replace(/__INDEX__/g, Date.now());
  }
}
