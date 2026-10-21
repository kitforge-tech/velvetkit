import { Controller } from "@hotwired/stimulus"

// Copies the source target's text and says so: the copy icon becomes a tick,
// a "Copied" label shows for a moment, and screen readers hear it through the
// status target. If the browser refuses the clipboard, the text is selected
// instead and the label asks for the keyboard shortcut.
//
// Icons are <svg>s, and `.hidden` is an HTMLElement property that an SVG
// ignores, so the hidden *attribute* is toggled; Tailwind's base styles
// enforce it.
export default class extends Controller {
  static targets = ["source", "idle", "done", "label", "status"]
  static values = { copied: { type: String, default: "Copied" }, failed: { type: String, default: "Press ⌘C or Ctrl+C to copy" } }

  async copy(event) {
    event?.preventDefault()
    const text = this.sourceTarget.textContent.trim()

    try {
      await navigator.clipboard.writeText(text)
      this.show(this.copiedValue, true)
    } catch {
      this.select()
      this.show(this.failedValue, false)
    }
  }

  show(message, copied) {
    this.idleTargets.forEach((el) => el.toggleAttribute("hidden", copied))
    this.doneTargets.forEach((el) => el.toggleAttribute("hidden", !copied))
    this.labelTargets.forEach((el) => { el.textContent = message; el.removeAttribute("hidden") })
    if (this.hasStatusTarget) this.statusTarget.textContent = message
    this.element.dataset.copied = ""

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.reset(), 1800)
  }

  reset() {
    this.idleTargets.forEach((el) => el.removeAttribute("hidden"))
    this.doneTargets.forEach((el) => el.setAttribute("hidden", ""))
    this.labelTargets.forEach((el) => el.setAttribute("hidden", ""))
    if (this.hasStatusTarget) this.statusTarget.textContent = ""
    delete this.element.dataset.copied
  }

  select() {
    const range = document.createRange()
    range.selectNodeContents(this.sourceTarget)
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
