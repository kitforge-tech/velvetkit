import { Controller } from "@hotwired/stimulus"

// Keeps the docs sidebar where it was across page visits.
//
// Turbo swaps in a fresh sidebar on every visit, scrolled to the top, so a
// link far down the list would vanish from view the moment it was clicked.
// The position is recorded as the sidebar scrolls (by disconnect the old
// sidebar is already detached and reports 0) and put back on the new one.
// With nothing recorded (a first visit, a reload) the current link is
// brought into view instead.
let remembered = null

export default class extends Controller {
  connect() {
    this.record = () => { remembered = this.element.scrollTop }
    this.element.addEventListener("scroll", this.record, { passive: true })

    // Now, before the first paint: restored a frame later, the new sidebar
    // is drawn at the top first and jumps back, a flicker on every visit.
    this.restore()
    // Again after layout, in case the sidebar had no height yet and the
    // browser ignored the position.
    requestAnimationFrame(() => this.restore())
  }

  restore() {
    if (remembered === null) this.element.querySelector("[aria-current=page]")?.scrollIntoView({ block: "center" })
    else if (this.element.scrollTop !== remembered) this.element.scrollTop = remembered
  }

  disconnect() {
    this.element.removeEventListener("scroll", this.record)
  }
}
