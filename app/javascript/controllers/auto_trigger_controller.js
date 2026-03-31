import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("auto-trigger connected")
    
    // Find the search controller and call hideSaveFormAfterSave
    const searchForm = document.getElementById('search-form')
    if (searchForm && searchForm.hasAttribute('data-controller')) {
      const searchController = this.application.getControllerForElementAndIdentifier(searchForm, 'search')
      if (searchController && typeof searchController.hideSaveFormAfterSave === 'function') {
        searchController.hideSaveFormAfterSave()
      }
    }
    
    // Remove this trigger element after a short delay
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.remove()
      }
    }, 100)
  }
}