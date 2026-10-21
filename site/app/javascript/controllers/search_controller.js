import { Controller } from "@hotwired/stimulus"

// The header search. Every guide and component is already in the list; typing
// hides what doesn't match and moves title matches to the top of each group.
// ↑ ↓ move, Enter opens, and ⌘K, Ctrl+K or / opens the search from anywhere.
export default class extends Controller {
  static targets = ["input", "group", "result", "empty"]

  connect() {
    this.onShortcut = (event) => {
      const typing = event.target.closest("input, textarea, select, [contenteditable]")
      const k = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k"
      if (!k && !(event.key === "/" && !typing)) return
      event.preventDefault()
      document.querySelector("[data-search-trigger]")?.click()
      requestAnimationFrame(() => { this.inputTarget.focus(); this.inputTarget.select() })
    }
    document.addEventListener("keydown", this.onShortcut)
    this.filter()
  }

  disconnect() {
    document.removeEventListener("keydown", this.onShortcut)
  }

  filter() {
    const words = this.inputTarget.value.trim().toLowerCase().split(/\s+/).filter(Boolean)

    this.resultTargets.forEach((result) => {
      const match = words.every((word) => result.dataset.searchText.includes(word))
      result.hidden = !match
      result.style.order = String(this.rank(result.dataset.searchTitle, words))
    })
    // Groups follow their best match, so the strongest result is on top.
    this.groupTargets.forEach((group) => {
      const ranks = [...group.querySelectorAll("[data-search-target=result]:not([hidden])")].map((r) => Number(r.style.order))
      group.hidden = ranks.length === 0
      group.style.order = ranks.length ? String(Math.min(...ranks)) : "9"
    })

    const visible = this.visible()
    this.emptyTarget.hidden = visible.length > 0
    this.activate(visible[0])
  }

  // Within a group: titles that start with the query, then titles containing
  // it, then matches only in the description or keywords.
  rank(title, words) {
    if (!words.length) return 0
    if (title.startsWith(words.join(" "))) return 0
    if (words.every((w) => title.includes(w))) return 1
    return 2
  }

  keydown(event) {
    const visible = this.visible()
    const index = visible.indexOf(this.active)
    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activate(visible[Math.min(index + 1, visible.length - 1)])
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activate(visible[Math.max(index - 1, 0)])
    } else if (event.key === "Enter" && this.active) {
      event.preventDefault()
      window.Turbo.visit(this.active.getAttribute("href"))
    } else if (event.key === "Escape") {
      // A search field spends the first Escape clearing itself, so the dialog
      // never hears it. Close it here, in one press.
      event.preventDefault()
      this.element.closest("dialog")?.close()
    }
  }

  hover(event) {
    this.activate(event.currentTarget, false)
  }

  activate(result, scroll = true) {
    this.resultTargets.forEach((r) => r.setAttribute("aria-selected", String(r === result)))
    this.active = result ?? null
    if (result) {
      this.inputTarget.setAttribute("aria-activedescendant", result.id)
      if (scroll) result.scrollIntoView({ block: "nearest" })
    } else {
      this.inputTarget.removeAttribute("aria-activedescendant")
    }
  }

  // Visible results in the order they appear on screen.
  visible() {
    const groups = [...this.groupTargets].sort((a, b) => (a.style.order || 0) - (b.style.order || 0))
    return groups.flatMap((group) =>
      [...group.querySelectorAll("[data-search-target=result]:not([hidden])")].sort((a, b) => (a.style.order || 0) - (b.style.order || 0))
    )
  }
}
