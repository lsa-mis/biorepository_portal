import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="options"
export default class extends Controller {
  static targets = ["fields", "show_options", "template", "question_type"];
  
  connect() {
    console.log("Options controller connected");
  }

  showOptions() {
    const questionType = this.question_typeTarget.value;
    console.log("Selected question type:", questionType);
    if (questionType === "dropdown" || questionType === "checkbox") {
      this.show_optionsTarget.classList.remove("invisible")
      this.show_optionsTarget.classList.add("visible")
    } else {
      console.log("Hiding options");
      this.show_optionsTarget.classList.remove("visible")
      this.show_optionsTarget.classList.add("invisible")
    }
  }

  append() {
    this.fieldsTarget.insertAdjacentHTML("beforeend", this.#templateContent);
  }

  // private

  get #templateContent() {
    return this.templateTarget.innerHTML.replace(/__INDEX__/g, Date.now());
  }
}
