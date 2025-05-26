import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit_options"
export default class extends Controller {
  static targets = ["fields", "show_options", "template", "question_type", "option_label", "option_value", "option_number"];
  
  connect() {
    console.log("Options controller connected");
    let thisOptionsNumber = -1 + document.querySelectorAll(".option-list-item").length;

    let option_label = this.option_labelTarget;
    console.log("option_label", option_label);

    this.option_labelTarget.setAttribute("for", `option_attributes_${thisOptionsNumber}_option`);
    this.option_labelTarget.textContent = `Option ${thisOptionsNumber}:`;

    this.option_valueTarget.setAttribute("value", `loan_question[options_attributes][${thisOptionsNumber}][option]`);
    this.option_valueTarget.setAttribute("id", `options_attributes_${thisOptionsNumber}_option`);

    this.option_numberTarget.setAttribute("value", thisOptionsNumber);
    this.option_numberTarget.setAttribute("name", `loan_question[options_attributes][${thisOptionsNumber}][number]`);
    this.option_numberTarget.setAttribute("id", `loan_question_options_attributes_${thisOptionsNumber}_number`);

    this.showOnlyLastRemoveOptionButton();
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
    let thisOptionsNumber = -1 + document.querySelectorAll(".option-list-item").length;

    let option_label = this.option_labelTarget;
    console.log("option_label", option_label);

    this.option_labelTarget.setAttribute("for", `option_attributes_${thisOptionsNumber}_option`);
    this.option_labelTarget.textContent = `Option ${thisOptionsNumber}:`;

    this.option_valueTarget.setAttribute("value", `loan_question[options_attributes][${thisOptionsNumber}][option]`);
    this.option_valueTarget.setAttribute("id", `options_attributes_${thisOptionsNumber}_option`);

    this.option_numberTarget.setAttribute("value", thisOptionsNumber);
    this.option_numberTarget.setAttribute("name", `loan_question[options_attributes][${thisOptionsNumber}][number]`);
    this.option_numberTarget.setAttribute("id", `loan_question_options_attributes_${thisOptionsNumber}_number`);

    this.showOnlyLastRemoveOptionButton();
  }

  get #templateContent() {
    return this.templateTarget.innerHTML;
  }

  removeOption() {
    this.element.remove();
    this.showOnlyLastRemoveOptionButton();
  }

  showOnlyLastRemoveOptionButton() {
    console.log("showOnlyLastRemoveOptionButton called");
    let btns = document.querySelectorAll(".remove-option-button")
    let btnsCount = btns.length;
    btns.forEach((btn, i) => {
      if (i !== btnsCount - 1) {
        btn.classList.add("display-none");
      } else {
        btn.classList.remove("display-none");
      }
    });
  }
}
