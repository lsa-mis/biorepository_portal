import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit_options"
export default class extends Controller {
  static targets = ["fields", "show_options", "template", "question_type", "option_label", "option_value", "option_number"];
  
  connect() {
    console.log("Options controller connected");
  }

  append() {
    console.log("append called");
    this.fieldsTarget.insertAdjacentHTML("beforeend", this.#templateContent);
    let thisOptionsNumber = document.querySelectorAll(".option-list-item").length;

    let option_label = this.option_labelTarget;
    console.log("option_label", option_label);

    this.option_labelTarget.setAttribute("for", `option_attributes_${thisOptionsNumber}_option`);
    this.option_labelTarget.textContent = `Option ${thisOptionsNumber}:`;

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
    console.log("removeOption called");
    console.log("this.element", this.element);
    this.element.remove();
    this.showOnlyLastRemoveOptionButton();
  }

  showOnlyLastRemoveOptionButton() {
    console.log("showOnlyLastRemoveOptionButton called");
    let btns = document.querySelectorAll(".remove-option-button")
    let btnsCount = btns.length -1;
    console.log("btnsCount", btnsCount);
    btns.forEach((btn, i) => {
      console.log("btn", btn);
      console.log("i", i);
      if (i < 2) {
        btn.classList.add("invisible");
      } else if (i !== btnsCount) {
        console.log("not equal to btnsCount")
        console.log("i", i)
        btn.classList.add("invisible");
      } else {
        console.log("equal to btnsCount")
        console.log("i", i)
        console.log("before", btn.classList)
        btn.classList.remove("invisible");
        console.log("after", btn.classList)
      }
    });
  }
}
