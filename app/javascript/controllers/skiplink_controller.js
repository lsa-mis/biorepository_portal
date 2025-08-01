import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("SkiplinkController connected")
    this.setupSkipLinks()
  }

  setupSkipLinks() {
    // Find all skip links in the document
    const skipLinks = document.querySelectorAll('.skiplink')
    
    skipLinks.forEach(link => {
      // Ensure skip links are focusable
      link.setAttribute('tabindex', '0')
      
      // Add click handler for better Safari support
      link.addEventListener('click', this.handleSkipLinkClick.bind(this))
      link.addEventListener('keydown', this.handleSkipLinkKeydown.bind(this))
      
      // Safari-specific focus handling
      if (this.isSafari()) {
        link.addEventListener('focus', (event) => {
          // Force visibility in Safari
          event.target.style.position = 'fixed'
          event.target.style.left = '10px'
          event.target.style.top = '10px'
          event.target.style.zIndex = '10001'
          event.target.style.display = 'block'
        })
      }
    })
  }

  isSafari() {
    return /^((?!chrome|android).)*safari/i.test(navigator.userAgent)
  }

  handleSkipLinkClick(event) {
    const link = event.target
    const targetId = link.getAttribute('href').substring(1)
    const targetElement = document.getElementById(targetId)
    
    if (targetElement) {
      event.preventDefault()
      
      // Scroll to the target smoothly
      targetElement.scrollIntoView({ 
        behavior: 'smooth', 
        block: 'start' 
      })
      
      // Focus the target element (important for Safari)
      if (!targetElement.hasAttribute('tabindex')) {
        targetElement.setAttribute('tabindex', '-1')
      }
      
      // Give the scroll time to complete before focusing
      setTimeout(() => {
        targetElement.focus()
      }, 300)
    }
  }

  handleSkipLinkKeydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.handleSkipLinkClick(event)
    }
  }
}
