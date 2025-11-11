# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Comprehensive Accessibility Checks', type: :system do
  before do
    visit root_path
  end

  it 'verifies page loads', skip_a11y: true do
    expect(page).to have_content('Biorepository').or have_content('Welcome')
  end

  it 'verifies accessibility helpers are included', skip_a11y: true do
    # Check that AccessibilityHelper module is included in system specs
    expect(self.class.included_modules).to include(AccessibilityHelper)
  end

  it 'verifies axe matcher is available', skip_a11y: true do
    # Verify Axe matchers are loaded
    expect(defined?(Axe::Matchers)).to be_truthy
  end

  # This test runs comprehensive accessibility checks
  # It includes all 11 checks:
  # Basic (5): form labels, images, interactive elements, headings, keyboard
  # Advanced (6): ARIA landmarks, form errors, tables, custom elements, duplicate IDs, skip links
  it 'runs comprehensive accessibility checks and reports any issues' do
    # Verify page loaded first
    expect(page).to have_content('Biorepository').or have_content('Welcome')
    
    # Run comprehensive accessibility checks
    # This will check all 11 accessibility requirements and provide detailed error messages
    # if any issues are found
    check_comprehensive_accessibility
  end
end
