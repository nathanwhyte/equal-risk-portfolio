import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash-toast"
export default class extends Controller {
  static targets = ["toast"]
  static values = { duration: Number }

  connect() {
    // Set default duration to 3000ms if not specified
    this.duration = this.hasDurationValue ? this.durationValue : 3000

    // Clean up URL: remove 'viewed' parameter if present (prevents flash on refresh)
    this.cleanupUrl()

    // Initialize all existing toasts
    this.initializeToasts()

    // Watch for new toast elements being added (e.g., via Turbo navigation)
    this.observer = new MutationObserver(() => {
      this.initializeToasts()
    })

    this.observer.observe(this.element, {
      childList: true,
      subtree: true
    })
  }

  cleanupUrl() {
    // Remove 'viewed' parameter from URL without reloading
    // This prevents the flash message from showing on page refresh
    const url = new URL(window.location.href)
    if (url.searchParams.has('viewed')) {
      url.searchParams.delete('viewed')
      // Update URL without triggering navigation
      window.history.replaceState({}, '', url.toString())
    }
  }

  disconnect() {
    // Clean up observer
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  initializeToasts() {
    // Get all toast targets (alert elements)
    // toastTargets returns an array of all matching targets
    this.toastTargets.forEach((toast) => {
      // Only schedule dismiss if not already scheduled
      if (!toast.dataset.dismissScheduled) {
        toast.dataset.dismissScheduled = "true"
        this.scheduleDismiss(toast)
      }
    })
  }

  scheduleDismiss(toastElement) {
    setTimeout(() => {
      // Add fade-out animation if needed
      toastElement.style.transition = "opacity 0.3s ease-out"
      toastElement.style.opacity = "0"

      // Remove from DOM after animation
      setTimeout(() => {
        toastElement.remove()
      }, 300)
    }, this.duration)
  }
}
