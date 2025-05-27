import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit_options"
export default class extends Controller {
  static targets = ["display_options", "question_type"];
  
  connect() {
    console.log("Show Options controller connected");
  }

  showOptions() {
    const questionType = this.question_typeTarget.value;
    console.log("Selected question type:", questionType);
    if (questionType === "dropdown" || questionType === "checkbox") {
      this.display_optionsTarget.classList.remove("invisible")
      this.display_optionsTarget.classList.add("visible")
    } else {
      console.log("Hiding options");
      this.display_optionsTarget.classList.remove("visible")
      this.display_optionsTarget.classList.add("invisible")
    }
  }

}
