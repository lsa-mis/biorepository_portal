import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="show-options"
export default class extends Controller {
  static targets = ["display_options", "question_type"];

  connect() {
    console.log("Show Options controller connected");
    // Immediately sync visibility & required-state on page load
    this.showOptions()
  }

  showOptions() {
    const qtype = this.question_typeTarget.value;
    const optionsContainer = this.display_optionsTarget;

    // Grab all of those <input data-edit-options-target="option_value"> inside the container
    const optionInputs = optionsContainer.querySelectorAll('[data-edit-options-target="option_value"]');

    if (qtype === "dropdown" || qtype === "checkbox") {
      // 1) Un-hide the options block
      optionsContainer.classList.remove("invisible");
      optionsContainer.classList.add("visible");

      // 2) Mark each input as required
      optionInputs.forEach((input) => {
        input.setAttribute("required", "true");
      });
    } else {
      // 1) Hide the options block
      optionsContainer.classList.remove("visible");
      optionsContainer.classList.add("invisible");

      // 2) Remove required from each (so validation is skipped)
      optionInputs.forEach((input) => {
        input.removeAttribute("required");
      });
    }
  }
}
