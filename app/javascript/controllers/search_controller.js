import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["group", "row", "rows", "groupTemplate", "groupsContainer", "form"]

  connect() {
    console.log("connect dynamic search")
    this.addOrSeparators()
    this.addAndSeparators()
  }

  removeField(event) {
    const row = event.currentTarget.closest(".search-row")
    const group = row.closest(".search-group")
    row.remove()

    // If group is empty, remove it
    if (!group.querySelector(".search-row")) {
      group.remove()
    }

    this.addOrSeparators()
    this.addAndSeparators()
    this.submit()
  }

  addRow(event) {
    const button = event.currentTarget
    const group = button.closest(".search-group")
    const rowsContainer = group.querySelector("[data-search-target='rows']")
    const referenceRow = group.querySelector(".search-row")
    if (!referenceRow || !rowsContainer) return

    const newRow = referenceRow.cloneNode(true)
    newRow.querySelectorAll("input, select").forEach(el => el.value = "")

    const groupIndex = this.getGroupIndex(group)
    const fieldIndex = rowsContainer.querySelectorAll(".search-row").length

    const baseName = `q[groupings][${groupIndex}][${fieldIndex}]`
    const selectId = `search_field_${groupIndex}_${fieldIndex}`

    const label = newRow.querySelector("label")
    const select = newRow.querySelector("select")
    const input = newRow.querySelector("input")

    if (label) label.setAttribute("for", selectId)
    if (select) {
      select.setAttribute("id", selectId)
      select.setAttribute("name", `${baseName}[field]`)
    }
    if (input) {
      input.setAttribute("name", `${baseName}[value]`)
    }

    rowsContainer.appendChild(newRow)
    this.addOrSeparators()
    this.addAndSeparators()
  }

  addGroup() {
    const template = this.groupTemplateTarget
    const container = this.groupsContainerTarget
    const groupIndex = container.querySelectorAll(".search-group").length

    const clone = template.content.cloneNode(true)
    const wrapper = document.createElement("div")
    wrapper.appendChild(clone)

    const newGroup = wrapper.querySelector(".search-group")
    newGroup.dataset.groupIndex = groupIndex

    // Replace placeholders in HTML template with actual groupIndex
    newGroup.innerHTML = newGroup.innerHTML.replace(/__GROUP_INDEX__/g, groupIndex)

    container.appendChild(newGroup)
    this.addOrSeparators()
    this.addAndSeparators()
  }

  addOrSeparators() {
    this.groupTargets.forEach(group => {
      const rows = group.querySelectorAll(".search-row")
      group.querySelectorAll(".or-label").forEach(el => el.remove())

      rows.forEach((row, index) => {
        if (index > 0) {
          const orLabel = document.createElement("span")
          orLabel.textContent = "OR"
          orLabel.classList.add("or-label", "badge", "badge-custom-blue", "mx-2")
          row.insertAdjacentElement("beforebegin", orLabel)
        }
      })
    })
  }

  addAndSeparators() {
    const container = this.groupsContainerTarget
    const groups = this.groupTargets

    // First, remove existing AND labels
    container.querySelectorAll(".and-label").forEach(el => el.remove())

    groups.forEach((group, index) => {
      if (index > 0) {
        const andLabel = document.createElement("span")
        andLabel.textContent = "AND"
        andLabel.classList.add("and-label", "badge", "badge-custom-blue", "my-2", "text-center")

        // Add spacing
        andLabel.style.display = "block"

        // Insert before this group
        group.parentNode.insertBefore(andLabel, group)
      }
    })
  }


  getGroupIndex(groupElement) {
    return Array.from(this.groupTargets).indexOf(groupElement)
  }

  submit(event) {
    const form = this.element

    this.formTarget.requestSubmit()
  }

  removeFilter(event) {
    event.preventDefault()
    const key = event.currentTarget.dataset.key
    const value = event.currentTarget.dataset.value
    
    // Find checkbox with name="q[key][]" and value="value"
    const checkboxName = `q[${key}][]`
    const checkboxes = document.querySelectorAll(`input[name="${checkboxName}"]`)
    
    checkboxes.forEach(checkbox => {
      if (checkbox.value === value) {
        checkbox.checked = false
      }
    })
    
    this.submit()
  }

}
