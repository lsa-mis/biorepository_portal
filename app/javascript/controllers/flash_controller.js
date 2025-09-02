import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = { timeout: Number, autoHide: Boolean }

  connect() {
    console.log("flash connect")
    
    // Check if auto-hide is disabled
    if (this.hasAutoHideValue && !this.autoHideValue) {
      return; // Don't set timeout if auto-hide is disabled
    }
    
    // Use custom timeout or default to 5000ms
    const timeout = this.hasTimeoutValue ? this.timeoutValue : 5000;
    setTimeout(() => { this.dismiss(); }, timeout)
  }
  
  dismiss() {
    this.element.remove();
  }
}
