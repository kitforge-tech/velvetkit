import { Controller } from "@hotwired/stimulus"

// Copies the source target's text, swapping the copy icon for a tick briefly.
//
// The icons toggle the hidden attribute, not a class: an icon carries
// `inline-block`, which beats a `hidden` class, so both icons showed at once.
// Tailwind's base styles enforce [hidden] with !important.
export default class extends Controller {
  static targets = ["source", "idle", "done"]

  async copy() {
    await navigator.clipboard.writeText(this.sourceTarget.textContent.trim())
    this.toggle(true)
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.toggle(false), 1500)
  }

  toggle(copied) {
    this.idleTargets.forEach((el) => { el.hidden = copied })
    this.doneTargets.forEach((el) => { el.hidden = !copied })
  }
}
