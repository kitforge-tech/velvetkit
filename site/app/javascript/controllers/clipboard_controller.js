import { Controller } from "@hotwired/stimulus"

// Copies the source target's text, swapping the copy icon for a tick briefly.
export default class extends Controller {
  static targets = ["source", "idle", "done"]

  async copy() {
    await navigator.clipboard.writeText(this.sourceTarget.textContent.trim())
    this.toggle(true)
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.toggle(false), 1500)
  }

  toggle(copied) {
    this.idleTargets.forEach((el) => el.classList.toggle("hidden", copied))
    this.doneTargets.forEach((el) => el.classList.toggle("hidden", !copied))
  }
}
