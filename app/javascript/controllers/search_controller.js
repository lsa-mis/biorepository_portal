import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group", "row", "rows", "groupTemplate", "groupsContainer"]

  connect() {
    console.log("connect search_controller")
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
    rowsContainer.appendChild(newRow)

    this.addOrSeparators()
  }

  addGroup() {
    const template = this.groupTemplateTarget
    const container = this.groupsContainerTarget

    const clone = template.content.cloneNode(true)
    container.appendChild(clone)

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
    console.log("submit search_controller")
    const form = this.element
    var filters = form.querySelectorAll("input[name^='q[']:checked")
    console.log("Filters:", filters);
    // filters.forEach((filter, index) => {
    //   console.log("Filter name:", filter.name);
    //   console.log("Filter value:", filter.value);
    //   if (filter.name && filter.value) {
    //       const input = document.createElement("input")
    //       input.type = "hidden"
    //       input.name = `q[groupings][${index}][${filter.name}]`
    //       input.value = filter.value
    //       form.appendChild(input)
    //     }
    // })
    

    form.querySelectorAll("input[name^='q[']").forEach(el => el.remove())

    this.groupTargets.forEach((group, groupIndex) => {
      const rows = group.querySelectorAll(".search-row")
      rows.forEach(row => {
        const field = row.querySelector(".dynamic-search-field")
        const value = row.querySelector(".dynamic-search-value")

        if (field.value && value.value) {
          const input = document.createElement("input")
          input.type = "hidden"
          input.name = `q[groupings][${groupIndex}][${field.value}]`
          input.value = value.value
          form.appendChild(input)
        }
      })
      filters.forEach((filter, index) => {
        console.log("Filter name:", filter.name);
        console.log("Filter value:", filter.value);
        if (filter.name && filter.value) {
            const input = document.createElement("input")
            input.type = "hidden"
            input.name = `q[groupings][${index}][${filter.name}]`
            input.value = filter.value
            form.appendChild(input)
          }
      })
    })
  }

  // submit() {
  //   console.log("submit form")
  //   Turbo.navigator.submitForm(this.formTarget)
  // }
}
