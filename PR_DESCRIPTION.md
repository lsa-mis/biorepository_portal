# Rails Accessibility Testing Gem

## 🎯 Overview

A comprehensive Rails gem that automatically runs accessibility checks on system specs and provides detailed, actionable error messages with specific remediation steps. This gem makes it easy to catch and fix accessibility issues during development.

## ✨ Key Features

### 🔍 Comprehensive Accessibility Checks (11 Checks)

**Basic Checks (5):**
- ✅ Form inputs have associated labels
- ✅ Images have alt attributes
- ✅ Interactive elements (links/buttons) have accessible names
- ✅ Proper heading hierarchy (h1 → h2 → h3)
- ✅ Keyboard accessibility for modals

**Advanced Checks (6):**
- ✅ ARIA landmarks (main, nav, etc.)
- ✅ Form error message associations
- ✅ Table structure with headers
- ✅ Custom element labels
- ✅ Duplicate ID detection
- ✅ Skip links (warning only)

### 📋 Batch Error Reporting

- **Collects ALL errors** instead of stopping at the first one
- **Summary at top**: Quick overview of all issues with locations
- **Detailed descriptions at bottom**: Full remediation steps for each error
- Makes it easy to fix multiple issues in one pass

### 🎯 Accurate View File Detection

- Automatically detects the **exact view file** where issues occur
- Handles **partials** (`_navbar.html.erb`, `_footer.html.erb`, etc.)
- Detects **layout files** based on element context
- Uses Rails routing for accurate controller/action detection
- Checks common partial locations: `app/views/{controller}/_partial`, `app/views/shared/_partial`, `app/views/layouts/_partial`

### 💬 Semantic Error Messages

- Uses clear, semantic terms: **"link"**, **"button"**, **"image"**, **"heading"** instead of generic tag names
- Includes specific element identifiers (href, id, src) in error titles
- Example: `Link missing accessible name (href: https://example.com)` instead of `A element missing accessible name`

### 🔧 Detailed Remediation Steps

Each error includes:
- **Where the error is**: Exact view file, URL, path
- **What element has the issue**: Tag, ID, classes, href/src, parent context
- **How to fix it**: Step-by-step remediation with code examples
- **Best practices**: WCAG guidelines and recommendations

### 🚀 Automatic Integration

- Automatically runs on all system specs
- No configuration needed - just require the gem
- Can be skipped per test with `skip_a11y: true` metadata
- Simple and straightforward - no complex setup

## 📦 Installation

Add to your `Gemfile`:

```ruby
gem 'rails_accessibility_testing', path: 'lib/rails_accessibility_testing'
```

Or if published as a gem:

```ruby
gem 'rails_accessibility_testing'
```

## 🎬 Usage

### Basic Usage

Just require the gem in `spec/rails_helper.rb`:

```ruby
require 'rails_accessibility_testing'
```

That's it! Comprehensive accessibility checks run automatically after each system spec.

### Manual Checks

```ruby
# In a system spec
it 'has no accessibility issues' do
  visit root_path
  check_comprehensive_accessibility  # All 11 checks
end

# Or just basic checks
check_basic_accessibility  # 5 basic checks
```

### Skip Checks

```ruby
it 'does something', skip_a11y: true do
  # This test won't run accessibility checks
end
```

## 📝 Example Error Output

```
======================================================================
❌ ACCESSIBILITY ERRORS FOUND: 2 issue(s)
======================================================================

📋 SUMMARY OF ISSUES:

  1. Image missing alt attribute (app/views/layouts/_navbar.html.erb) [src: LSA_Logo.svg]
  2. Link missing accessible name (app/views/layouts/_navbar.html.erb) [href: https://lsa.umich.edu/]

======================================================================
📝 DETAILED ERROR DESCRIPTIONS:
======================================================================

----------------------------------------------------------------------
ERROR 1 of 2:
----------------------------------------------------------------------

======================================================================
❌ ACCESSIBILITY ERROR: Image missing alt attribute
======================================================================

📄 Page Being Tested:
   URL: http://127.0.0.1:53341/
   Path: /
   📝 Likely View File: app/views/layouts/_navbar.html.erb

📍 Element Details:
   Tag: <img>
   ID: (none)
   Classes: logo_image
   Src: /assets/LSA_Logo.svg
   Visible text: (empty)
   Parent: <div id="LSAlogo" class="d-flex align-items-center">

🔧 HOW TO FIX:
   Choose ONE of these solutions:

   1. Add alt text for informative images:
      <img src="/assets/LSA_Logo.svg" alt="Description of image">

   2. Add empty alt for decorative images:
      <img src="/assets/LSA_Logo.svg" alt="">

   3. Use Rails image_tag helper:
      <%= image_tag 'LSA_Logo.svg', alt: 'Description' %>

   💡 Best Practice: All images must have alt attribute.
      Use empty alt="" only for purely decorative images.

📖 WCAG Reference: https://www.w3.org/WAI/WCAG21/Understanding/
======================================================================
```

## 🏗️ Architecture

### Core Components

- **`AccessibilityHelper`**: Main module with all check methods
- **`ErrorMessageBuilder`**: Formats error messages with remediation steps
- **`RSpecIntegration`**: Auto-configures RSpec to run checks
- **`Configuration`**: Simple configuration options
- **`SharedExamples`**: Reusable RSpec shared examples

### Error Collection System

- Errors are collected in `@accessibility_errors` array
- All checks complete before raising errors
- Errors formatted with summary at top, details at bottom
- Each error includes full context and remediation steps

## 🎨 Design Decisions

1. **Semantic Error Titles**: Uses "link", "button", "image" instead of tag names for clarity
2. **Batch Error Reporting**: Shows all errors at once for efficiency
3. **Accurate File Detection**: Uses element context to find exact partial/layout files
4. **Remediation in ErrorMessageBuilder**: Separation of concerns - helper detects, builder formats
5. **Simple Integration**: No complex configuration needed

## 🧪 Testing

The gem includes comprehensive specs:

- `spec/system/alt_text_error_spec.rb` - Image alt text checks
- `spec/system/comprehensive_accessibility_spec.rb` - Full comprehensive checks

## 📚 Documentation

- `README.md` - Main documentation
- `SETUP_GUIDE.md` - Detailed setup instructions
- `DEPENDENCIES.md` - Required dependencies

## 🔄 What's Changed

### New Features
- ✅ Batch error collection and reporting
- ✅ Accurate view file detection (partials & layouts)
- ✅ Semantic error titles with element identifiers
- ✅ Comprehensive error messages with remediation steps
- ✅ Simplified integration (removed complex change detection)

### Improvements
- ✅ Better error message formatting
- ✅ More accurate file detection using element context
- ✅ All errors shown together instead of stopping at first
- ✅ Clearer, more actionable remediation steps

## 🚦 Status

Ready for use! The gem is fully functional and tested.

## 📄 License

[Your License Here]

---

**Built with ❤️ for accessible Rails applications**

