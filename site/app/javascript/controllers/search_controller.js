import { Controller } from "@hotwired/stimulus"
import { missReporter, track } from "../analytics"

// The header search is the kit's Command palette; this only tells analytics
// what people searched for and didn't find, and which result they picked.
export default class extends Controller {
  connect() {
    this.miss = missReporter("header")
  }

  disconnect() {
    this.miss.cancel()
  }

  searched({ detail: { query, matches } }) {
    if (matches > 0 || !query) this.miss.cancel()
    else this.miss.report(query)
  }

  picked({ detail: { href } }) {
    track("search_select", { result: href })
  }
}
