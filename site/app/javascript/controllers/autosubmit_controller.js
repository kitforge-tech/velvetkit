import { Controller } from "@hotwired/stimulus"

// Submits the form a moment after typing stops.
export default class extends Controller {
  submit() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), 250)
  }
}
