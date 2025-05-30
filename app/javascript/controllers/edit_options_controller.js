import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit_options"
export default class extends Controller {
  static targets = ["fields", "show_options", "template", "question_type", "option_label", "option_value", "option_number", "remove_button", "add_option_button"];
  
  connect() {
    console.log("Options controller connected");
    this.showOnlyLastRemoveOptionButton();
  }

  append() {
    console.log("append called");

    const thisOptionsNumber = Array.from(document.querySelectorAll(".option-list-item"))
                               .filter(item => item.style.display !== "none").length;
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

    this.renumberOptionLabels();
  }

  removeOption(event) {
    event.preventDefault();

    const allOptionItems = Array.from(document.querySelectorAll(".option-list-item"));
    const visibleOptions = allOptionItems.filter(item => item.style.display !== "none");

    if (visibleOptions.length <= 2) return;

    const button = event.currentTarget;
    const optionItem = button.closest(".option-list-item");

    // Only allow removing the last visible option
    if (optionItem !== visibleOptions[visibleOptions.length - 1]) return;

    const destroyField = optionItem.querySelector('input[name*="_destroy"]');
    const idField = optionItem.querySelector('input[name*="[id]"]');
    
    if (destroyField && idField && idField.value) {
      destroyField.value = "1";
      destroyField.checked = true;
      optionItem.style.display = "none";
    } else {
      optionItem.remove();
    }

    this.showOnlyLastRemoveOptionButton();

    this.renumberOptionLabels();
  }

  showOnlyLastRemoveOptionButton() {
    const allOptionItems = Array.from(document.querySelectorAll(".option-list-item"));
    const visibleOptionItems = allOptionItems.filter(item => item.style.display !== "none");

    const removeButtons = visibleOptionItems.map(item =>
      item.querySelector(".remove-option-button")
    );

    removeButtons.forEach((btn, i) => {
      if (i < 2 || i !== removeButtons.length - 1) {
        btn.classList.add("invisible");
      } else {
        btn.classList.remove("invisible");
      }
    });
  }

  renumberOptionLabels() {
    const visibleItems = Array.from(document.querySelectorAll(".option-list-item"))
                              .filter(item => item.style.display !== "none");

    visibleItems.forEach((item, index) => {
      const label = item.querySelector('[data-edit-options-target="option_label"]');
      if (label) {
        label.textContent = `Option ${index + 1}`;
      }
    });
  }
}
