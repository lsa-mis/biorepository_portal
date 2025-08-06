import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio"]

  change(event) {
    const addressId = event.target.value
    const url = `/addresses/${addressId}/set_primary`
    
    fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Update UI to reflect the change
        this.updatePrimaryBadges(addressId)
        console.log('Primary address updated successfully')
      } else {
        console.error('Failed to update primary address')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      // Optionally revert the radio button selection on error
      event.target.checked = false
    })
  }

  updatePrimaryBadges(selectedAddressId) {
    // Remove all primary badges
    const allBadges = document.querySelectorAll('.badge.bg-primary')
    allBadges.forEach(badge => {
      if (badge.textContent.trim() === 'Primary') {
        badge.remove()
      }
    })

    // Remove border styling from all cards
    const allCards = document.querySelectorAll('.address-card')
    allCards.forEach(card => {
      card.classList.remove('border-primary')
      const cardBody = card.querySelector('.card-body')
      if (cardBody) {
        cardBody.classList.remove('bg-light', 'border', 'border-primary')
      }
    })

    // Add primary badge and styling to selected address
    const selectedCard = document.querySelector(`label[for="shipment_${selectedAddressId}"]`)
    if (selectedCard) {
      selectedCard.classList.add('border-primary')
      const cardBody = selectedCard.querySelector('.card-body')
      if (cardBody) {
        cardBody.classList.add('bg-light', 'border', 'border-primary')
        
        // Add primary badge if it doesn't exist
        if (!cardBody.querySelector('.badge.bg-primary')) {
          const primaryBadge = document.createElement('span')
          primaryBadge.classList.add('badge', 'bg-primary', 'mb-2')
          primaryBadge.textContent = 'Primary'
          cardBody.insertBefore(primaryBadge, cardBody.firstChild)
        }
      }
    }
  }
}
