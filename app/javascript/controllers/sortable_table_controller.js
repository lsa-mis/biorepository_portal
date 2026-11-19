import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sortable-table"
// Sorts the table body by a column when its header button is clicked.
// Rows are sorted by each cell's data-sort-value; aria-sort on the header announces the order.
export default class extends Controller {
  static targets = ["header", "body"]

  sort({ params: { column, type } }) {
    const header = this.headerTargets[column]
    const current = header.getAttribute("aria-sort")
    // Text columns start A to Z, number columns start with the largest count
    const direction = current === "none"
      ? (type === "number" ? "descending" : "ascending")
      : (current === "ascending" ? "descending" : "ascending")

    const rows = Array.from(this.bodyTarget.rows)
    const collator = new Intl.Collator(undefined, { numeric: true, sensitivity: "base" })
    const value = (row) => row.cells[column].dataset.sortValue

    rows.sort((a, b) => {
      const result = type === "number"
        ? Number(value(a)) - Number(value(b))
        : collator.compare(value(a), value(b))
      return direction === "ascending" ? result : -result
    })
    this.bodyTarget.append(...rows)

    this.headerTargets.forEach((th, index) => {
      th.setAttribute("aria-sort", index === column ? direction : "none")
      th.querySelector("i").className = this.iconClass(th.getAttribute("aria-sort"))
    })
  }

  iconClass(sort) {
    if (sort === "ascending") return "bi bi-arrow-up"
    if (sort === "descending") return "bi bi-arrow-down"
    return "bi bi-arrow-down-up text-muted"
  }
}
