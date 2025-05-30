import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit_options"
export default class extends Controller {
  static targets = ["fields", "show_options", "template", "question_type", "option_label", "option_value", "option_number", "remove_button", "add_option_button"];
  
  connect() {
    console.log("Options controller connected");
  }

  append() {
    console.log("append called");

    const thisOptionsNumber = document.querySelectorAll(".option-list-item").length;
    const newOptionNumber = thisOptionsNumber + 1;
    console.log("thisOptionsNumber", thisOptionsNumber);

    // Clone template and extract the DOM node
    const templateContent = this.templateTarget.content.cloneNode(true);
    const newOptionElement = templateContent.querySelector(".option-list-item");

    // Update label
    const optionLabel = newOptionElement.querySelector('[data-edit-options-target="option_label"]');
    optionLabel.textContent = `Option ${newOptionNumber}`;
    optionLabel.setAttribute("for", `option_attributes_${newOptionNumber}_option`);

    // Update input field
    const optionInput = newOptionElement.querySelector('[data-edit-options-target="option_value"]');
    optionInput.setAttribute("id", `option_attributes_${newOptionNumber}_option`);
    optionInput.setAttribute("name", `option_attributes[${newOptionNumber}][value]`);

    // Update remove button
    const removeButton = newOptionElement.querySelector('[data-edit-options-target="remove_button"]');
    removeButton.setAttribute("id", `remove-option-${newOptionNumber}`);

    // Update option number input (if needed)
    const optionNumber = newOptionElement.querySelector('[data-edit-options-target="option_number"]');
    if (optionNumber) {
      optionNumber.setAttribute("value", newOptionNumber);
      optionNumber.setAttribute("id", `option_number_${newOptionNumber}`);
      optionNumber.setAttribute("name", `option_attributes[${newOptionNumber}][number]`);
    }

    // Append new option block
    this.fieldsTarget.appendChild(newOptionElement);

    this.showOnlyLastRemoveOptionButton();
  }

  removeOption(event) {
    event.preventDefault();

    const allOptions = document.querySelectorAll(".option-list-item");
    const button = event.currentTarget;
    const optionItem = button.closest(".option-list-item");

    if (allOptions.length <= 2) return;
    
    if (optionItem) {
      optionItem.remove();
      this.showOnlyLastRemoveOptionButton();
    }
  }

  showOnlyLastRemoveOptionButton() {
    console.log("showOnlyLastRemoveOptionButton called");
    let btns = document.querySelectorAll(".remove-option-button")
    let btnsCount = btns.length -1;
    console.log("btnsCount", btnsCount);
    btns.forEach((btn, i) => {
      // console.log("btn", btn);
      // console.log("i", i);
      if (i < 2) {
        btn.classList.add("invisible");
      } else if (i !== btnsCount) {
        // console.log("not equal to btnsCount")
        // console.log("i", i)
        btn.classList.add("invisible");
      } else {
        // console.log("equal to btnsCount")
        // console.log("i", i)
        // console.log("before", btn.classList)
        btn.classList.remove("invisible");
        // console.log("after", btn.classList)
      }
    });
  }
}
