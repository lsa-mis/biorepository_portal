---
applyTo: "app/views/**/*.erb,app/helpers/**/*.rb,app/javascript/**/*.js,app/assets/stylesheets/**/*.scss"
---

# Accessibility review

This portal must meet **WCAG 2.1 Level AA** (the University of Michigan standard). When reviewing changes to views, helpers, JavaScript or styles, check the changed code for the problems below. For each problem, name the WCAG success criterion (for example "1.4.1 Use of Color") and say how severe it is for a user: blocks the task, makes it hard, or minor.

The UI uses Rails ERB views, Bootstrap 5, Turbo and Stimulus controllers.

## What to check

- **Names for everything interactive.** Every link, button, form control and icon-only control has an accessible name that includes its visible text (1.1.1, 2.4.4, 2.5.3, 4.1.2). Flag `link_to`/`button_to` with only an icon, `<a>` without `href` used as a button, and click handlers on `div`/`span`.
- **Form fields.** Each input has a `<label for>` or `aria-labelledby`; required fields and errors are announced, not shown by color alone. Error messages are tied to their field with `aria-describedby` (1.3.1, 3.3.1, 3.3.2).
- **Headings and landmarks.** Heading levels go up one at a time with no skipped levels. Each page has one `h1` and a `main` landmark (1.3.1, 2.4.6).
- **Links in text.** Links inside a paragraph must be distinguishable without color, for example with an underline (1.4.1).
- **Contrast.** Text is at least 4.5:1, large text and UI component borders at least 3:1 (1.4.3, 1.4.11). Watch custom colors in `_custom.scss`.
- **Images.** Informative images have meaningful `alt`; decorative images use `alt=""` (1.1.1).
- **Keyboard.** Everything works with the keyboard; focus is visible and never removed with `outline: none` without a replacement; no keyboard traps (2.1.1, 2.1.2, 2.4.7).
- **Dynamic updates.** Turbo Frame/Stream updates, Stimulus toggles and flash messages that change content without a page load are announced (for example with `role="status"` or `aria-live`), and focus moves sensibly when a dialog opens or closes (4.1.3, 2.4.3).
- **Bootstrap components.** Modals, dropdowns, collapses and tabs keep Bootstrap's ARIA attributes (`aria-expanded`, `aria-controls`, `aria-labelledby`) in sync. `.visually-hidden` text is intentional and should not be flagged as clipped.
- **Tables.** Data tables use `<th>` with `scope` and a caption or accessible name (1.3.1).
- **Zoom and reflow.** Layouts work at 320 px wide and 200% zoom without horizontal scrolling or clipped text (1.4.4, 1.4.10).

Do not claim a change makes the page WCAG compliant; automated review cannot prove that. Point to the exact line and suggest a concrete fix.
