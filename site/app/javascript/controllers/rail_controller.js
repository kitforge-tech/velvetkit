import { Controller } from "@hotwired/stimulus"

// A horizontal rail of cards: the arrow buttons scroll it by about a card's
// width, and grey out at either end. The track itself scrolls by touch,
// trackpad, or ← → once focused, so the buttons are a convenience.
export default class extends Controller {
  static targets = ["track", "previous", "next"]

  connect() {
    this.update()
    this.onResize = () => this.update()
    window.addEventListener("resize", this.onResize)
  }

  disconnect() {
    window.removeEventListener("resize", this.onResize)
  }

  previous() {
    this.trackTarget.scrollBy({ left: -this.step(), behavior: "smooth" })
  }

  next() {
    this.trackTarget.scrollBy({ left: this.step(), behavior: "smooth" })
  }

  // The buttons grey out at either end, and the track's edge fade only shows
  // on a side with more cards beyond it.
  update() {
    const track = this.trackTarget
    const atStart = track.scrollLeft <= 2
    const atEnd = track.scrollLeft >= track.scrollWidth - track.clientWidth - 2
    this.previousTarget.disabled = atStart
    this.nextTarget.disabled = atEnd
    track.toggleAttribute("data-at-start", atStart)
    track.toggleAttribute("data-at-end", atEnd)
  }

  // A card's width plus the gap.
  step() {
    const card = this.trackTarget.firstElementChild
    const gap = parseFloat(getComputedStyle(this.trackTarget).columnGap) || 0
    return card ? card.getBoundingClientRect().width + gap : this.trackTarget.clientWidth * 0.8
  }
}
