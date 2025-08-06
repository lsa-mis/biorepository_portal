import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "stepIndicator", "nextBtn", "prevBtn", "submitBtn"]

  connect() {
    this.currentStep = 0
    this.showStep(this.currentStep)
  }

  next() {
    if (this.currentStep < this.stepTargets.length - 1) {
      this.currentStep++
      this.showStep(this.currentStep)
    }
  }

  previous() {
    if (this.currentStep > 0) {
      this.currentStep--
      this.showStep(this.currentStep)
    }
  }

  showStep(step) {
    // Hide all steps and reset step indicators
    this.stepTargets.forEach((el, idx) => {
      el.classList.toggle("d-none", idx !== step)
      
      // Reset step indicator styling
      const circle = this.stepIndicatorTargets[idx].querySelector(".circle")
      circle.classList.remove("bg-primary")
      circle.classList.add("bg-secondary")
    })

    // Show current step and update its indicator
    this.stepTargets[step].classList.remove("d-none")
    const currentCircle = this.stepIndicatorTargets[step].querySelector(".circle")
    currentCircle.classList.remove("bg-secondary")
    currentCircle.classList.add("bg-primary")

    // Update button states
    this.prevBtnTarget.disabled = step === 0
    this.nextBtnTarget.classList.toggle("d-none", step === this.stepTargets.length - 1)
    this.submitBtnTarget.classList.toggle("d-none", step !== this.stepTargets.length - 1)
  }
}
