import { Controller } from "@hotwired/stimulus"
import { missReporter } from "../analytics"

// Hides items whose data-filter-text doesn't contain what was typed.
export default class extends Controller {
  static targets = ["item", "empty", "count"]

  connect() {
    this.miss = missReporter("components")
  }

  disconnect() {
    this.miss.cancel()
  }

  filter(event) {
    const query = event.target.value.trim().toLowerCase()
    let shown = 0
    this.itemTargets.forEach((item) => {
      const match = item.dataset.filterText.includes(query)
      item.hidden = !match
      if (match) shown++
    })
    this.emptyTarget.hidden = shown > 0
    this.countTarget.textContent = shown

    if (shown) this.miss.cancel()
    else this.miss.report(query)
  }
}
