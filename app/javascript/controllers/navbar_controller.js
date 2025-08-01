import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]

  connect() {
    console.log("NavbarController connected")
    this.setupKeyboardNavigation()
    this.setupCrossBrowserCompatibility()
    this.addGlobalEventListeners()
  }

  setupKeyboardNavigation() {
    // Find all dropdown triggers in the navbar
    const dropdownTriggers = this.element.querySelectorAll('[data-bs-toggle="dropdown"]')
    
    dropdownTriggers.forEach(trigger => {
      // Ensure the element is focusable with proper tabindex
      trigger.setAttribute('tabindex', '0')
      trigger.setAttribute('role', 'button')
      trigger.setAttribute('aria-haspopup', 'true')
      trigger.setAttribute('aria-expanded', 'false')
      
      // Add keyboard event listeners
      trigger.addEventListener('keydown', this.handleDropdownKeydown.bind(this))
      trigger.addEventListener('focus', this.handleFocus.bind(this))
    })

    // Handle all other navigation links
    const navLinks = this.element.querySelectorAll('a:not([data-bs-toggle="dropdown"])')
    navLinks.forEach(link => {
      link.addEventListener('keydown', this.handleNavLinkKeydown.bind(this))
    })
  }

  setupCrossBrowserCompatibility() {
    // Firefox and Safari need explicit focus handling
    const allFocusableElements = this.element.querySelectorAll('a, button, [tabindex]:not([tabindex="-1"])')
    
    allFocusableElements.forEach(element => {
      // Ensure proper tabindex for cross-browser compatibility
      if (!element.hasAttribute('tabindex') || element.getAttribute('tabindex') === '') {
        element.setAttribute('tabindex', '0')
      }
      
      // Add focus/blur handlers for consistent styling
      element.addEventListener('focus', this.handleElementFocus.bind(this))
      element.addEventListener('blur', this.handleElementBlur.bind(this))
    })

    // Safari-specific fixes
    if (this.isSafari()) {
      this.applySafariFixes()
    }

    // Firefox-specific fixes  
    if (this.isFirefox()) {
      this.applyFirefoxFixes()
    }
  }

  isSafari() {
    return /^((?!chrome|android).)*safari/i.test(navigator.userAgent)
  }

  isFirefox() {
    return navigator.userAgent.toLowerCase().indexOf('firefox') > -1
  }

  applySafariFixes() {
    // Safari needs explicit handling for dropdown toggles
    const dropdownTriggers = this.element.querySelectorAll('[data-bs-toggle="dropdown"]')
    dropdownTriggers.forEach(trigger => {
      // Force Safari to recognize these as interactive elements
      trigger.style.cursor = 'pointer'
      
      // Safari needs explicit click event binding
      trigger.addEventListener('click', (event) => {
        event.preventDefault()
        this.toggleDropdownForSafari(trigger)
      })
    })
  }

  applyFirefoxFixes() {
    // Firefox sometimes needs preventDefault on keydown for proper handling
    const allInteractiveElements = this.element.querySelectorAll('a, button, [data-bs-toggle]')
    allInteractiveElements.forEach(element => {
      element.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          // Let the specific handlers deal with preventDefault
          return
        }
      })
    })
  }

  handleDropdownKeydown(event) {
    const trigger = event.target
    
    // Handle Enter, Space, and Arrow Down keys for dropdowns
    if (event.key === 'Enter' || event.key === ' ' || event.key === 'ArrowDown') {
      event.preventDefault()
      event.stopPropagation()
      this.openDropdown(trigger)
      return false
    }
    
    // Handle Escape key
    if (event.key === 'Escape') {
      event.preventDefault()
      this.closeDropdown(trigger)
      return false
    }
  }

  handleNavLinkKeydown(event) {
    const link = event.target
    
    // Handle Enter and Space for regular navigation links
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      // Trigger the link navigation
      if (link.href) {
        window.location.href = link.href
      } else if (link.onclick) {
        link.onclick()
      } else {
        link.click()
      }
      return false
    }
  }

  handleFocus(event) {
    // Ensure proper ARIA states on focus
    const trigger = event.target
    if (trigger.hasAttribute('data-bs-toggle')) {
      // Don't change aria-expanded here, let Bootstrap handle it
    }
  }

  handleElementFocus(event) {
    // Add visual focus indicator for all browsers
    const element = event.target
    element.style.outline = '2px solid #E5E5E5'
    element.style.outlineOffset = '2px'
  }

  handleElementBlur(event) {
    // Remove explicit outline styling on blur
    const element = event.target
    element.style.outline = ''
    element.style.outlineOffset = ''
  }

  toggleDropdownForSafari(trigger) {
    // Special Safari dropdown handling
    if (window.bootstrap && window.bootstrap.Dropdown) {
      const dropdownInstance = window.bootstrap.Dropdown.getInstance(trigger)
      if (dropdownInstance) {
        dropdownInstance.toggle()
      } else {
        const dropdown = new window.bootstrap.Dropdown(trigger)
        dropdown.show()
      }
    }
  }

  openDropdown(trigger) {
    // Close any other open dropdowns first
    this.closeAllDropdowns()
    
    // Use Bootstrap's dropdown API
    if (window.bootstrap && window.bootstrap.Dropdown) {
      try {
        const dropdown = window.bootstrap.Dropdown.getOrCreateInstance(trigger)
        dropdown.show()
        
        // Focus first dropdown item after a brief delay
        setTimeout(() => {
          const dropdownMenu = trigger.nextElementSibling
          if (dropdownMenu) {
            const firstItem = dropdownMenu.querySelector('.dropdown-item')
            if (firstItem) {
              firstItem.focus()
            }
          }
        }, 100)
      } catch (error) {
        console.warn('Bootstrap dropdown failed:', error)
        this.fallbackDropdownOpen(trigger)
      }
    } else {
      this.fallbackDropdownOpen(trigger)
    }
  }

  fallbackDropdownOpen(trigger) {
    // Manual dropdown opening as fallback
    const dropdownMenu = trigger.nextElementSibling
    if (dropdownMenu && dropdownMenu.classList.contains('dropdown-menu')) {
      dropdownMenu.classList.add('show')
      trigger.setAttribute('aria-expanded', 'true')
      
      // Focus first dropdown item
      const firstItem = dropdownMenu.querySelector('.dropdown-item')
      if (firstItem) {
        setTimeout(() => firstItem.focus(), 50)
      }
    }
  }

  closeDropdown(trigger) {
    if (window.bootstrap && window.bootstrap.Dropdown) {
      try {
        const dropdown = window.bootstrap.Dropdown.getInstance(trigger)
        if (dropdown) {
          dropdown.hide()
        }
      } catch (error) {
        console.warn('Bootstrap dropdown close failed:', error)
        this.fallbackDropdownClose(trigger)
      }
    } else {
      this.fallbackDropdownClose(trigger)
    }
  }

  fallbackDropdownClose(trigger) {
    const dropdownMenu = trigger.nextElementSibling
    if (dropdownMenu && dropdownMenu.classList.contains('dropdown-menu')) {
      dropdownMenu.classList.remove('show')
      trigger.setAttribute('aria-expanded', 'false')
      trigger.focus()
    }
  }

  closeAllDropdowns() {
    const allDropdowns = this.element.querySelectorAll('.dropdown-menu.show')
    allDropdowns.forEach(menu => {
      menu.classList.remove('show')
      const trigger = menu.previousElementSibling
      if (trigger) {
        trigger.setAttribute('aria-expanded', 'false')
      }
    })
  }

  addGlobalEventListeners() {
    // Handle clicks outside dropdown to close
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closeAllDropdowns()
    }
  }

  disconnect() {
    // Clean up event listeners
    if (this.handleClickOutside) {
      document.removeEventListener('click', this.handleClickOutside)
    }
  }
}
