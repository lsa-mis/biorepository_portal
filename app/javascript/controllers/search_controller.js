import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group", "row", "rows", "groupTemplate", "groupsContainer", "form"]
	connect() {
    console.log("connect dynamic search")
    // this.application = this.application || window.Stimulus
  }

  removeField(event) {
    const row = event.currentTarget.closest(".search-row")
    const group = row.closest(".search-group")

    row.remove()

    // If group has no rows left, remove the group
    if (!group.querySelector(".search-row")) {
      group.remove()
    }

    this.addOrSeparators()
  }

  addRow(event) {
    // Identify the button's group
    const button = event.currentTarget
    const group = button.closest(".search-group")
    const rowsContainer = group.querySelector("[data-search-target='rows']")
    const referenceRow = group.querySelector(".search-row")

    if (!referenceRow || !rowsContainer) return

    const newRow = referenceRow.cloneNode(true)
    newRow.querySelectorAll("input, select").forEach(el => el.value = "")

    // Get next index
    const fieldIndex = rowsContainer.querySelectorAll(".search-row").length
    const groupIndex = group.dataset.groupIndex || 0

    const selectId = `search_field_${groupIndex}_${fieldIndex}`

    // Update IDs
    const label = newRow.querySelector("label[for^='search_field_']")
    const select = newRow.querySelector("select[id^='search_field_']")
    const input = newRow.querySelector("input")

    if (label && select) {
      label.setAttribute("for", selectId)
      select.setAttribute("id", selectId)
      select.setAttribute("name", `dynamic_fields[${groupIndex}_${fieldIndex}][field]`)
    }

    if (input) {
      input.setAttribute("name", `dynamic_fields[${groupIndex}_${fieldIndex}][value]`)
    }

    rowsContainer.appendChild(newRow)

    this.addOrSeparators()
  }

  addGroup() {
    const template = this.groupTemplateTarget
    const container = this.groupsContainerTarget

    const clone = template.content.cloneNode(true)
    const wrapper = document.createElement("div")
    wrapper.appendChild(clone)

    const newGroup = wrapper.querySelector(".search-group")

    // Compute group index
    const groupIndex = container.querySelectorAll(".search-group").length
    newGroup.dataset.groupIndex = groupIndex

    const row = newGroup.querySelector(".search-row")
    const label = row.querySelector("label")
    const select = row.querySelector("select")
    const input = row.querySelector("input")

    const fieldIndex = 0
    const newId = `search_field_${groupIndex}_${fieldIndex}`

    if (label) label.setAttribute("for", newId)
    if (select) {
      select.setAttribute("id", newId)
      select.setAttribute("name", `dynamic_fields[${groupIndex}_${fieldIndex}][field]`)
    }
    if (input) {
      input.setAttribute("name", `dynamic_fields[${groupIndex}_${fieldIndex}][value]`)
      input.value = ""
    }

    container.appendChild(newGroup)

    this.addOrSeparators()
  }

  addOrSeparators() {
    this.groupTargets.forEach(group => {
      const rows = group.querySelectorAll(".search-row")
      group.querySelectorAll(".or-label").forEach(el => el.remove())

      rows.forEach((row, index) => {
        if (index > 0) {
          const orLabel = document.createElement("span")
          orLabel.textContent = "OR"
          orLabel.classList.add("or-label", "badge", "bg-info", "mx-2")
          row.insertAdjacentElement("beforebegin", orLabel)
        }
      })
    })
  }

  submit(event) {
    const form = this.element;
		form
    .querySelectorAll("input[name^='q[groupings]']")
    .forEach(el => el.remove())
    this.groupTargets.forEach((group, groupIndex) => {
      const rows = group.querySelectorAll(".search-row");
      // Add group-level m=or for OR logic within the group
      const mInput = document.createElement("input");
      mInput.type = "hidden";
      mInput.name = `q[groupings][${groupIndex}][m]`;
      mInput.value = "or";
      form.appendChild(mInput);
      // Collect all field/value pairs for this group
      const fieldMap = {};
      rows.forEach((row) => {
        const field = row.querySelector(".dynamic-search-field");
        const value = row.querySelector(".dynamic-search-value");
        if (field && value && field.value && value.value) {
          if (!fieldMap[field.value]) fieldMap[field.value] = [];
          fieldMap[field.value].push(value.value);
        }
      });
      // Add hidden inputs for each field/value (as array if multiple)
      Object.entries(fieldMap).forEach(([fieldName, values]) => {
        if (values.length === 1) {
          const input = document.createElement("input");
          input.type = "hidden";
          input.name = `q[groupings][${groupIndex}][${fieldName}]`;
          input.value = values[0];
          form.appendChild(input);
        } else {
          values.forEach(val => {
            const input = document.createElement("input");
            input.type = "hidden";
            input.name = `q[groupings][${groupIndex}][${fieldName}][]`;
            input.value = val;
            form.appendChild(input);
          });
        }
      });
    });
		// Submit the form
    this.formTarget.requestSubmit();
  }
}
