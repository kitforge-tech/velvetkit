// Umami analytics for the VelvetKit docs site.
//
// The site is an adoption funnel: land on the home page, read the docs, copy
// an install command, add components. Every event here maps to a stage in
// that funnel or a signal that a visitor is evaluating the kit seriously.
//
// Element-level click events use data-umami-event attributes in templates.
// This module covers behaviours that need JavaScript.

const tracker = () => window.umami

// ── Turbo page views ────────────────────────────────────────────────────
// Umami auto-tracks the first full page load. Turbo navigations skip
// DOMContentLoaded, so fire a manual pageview for each one. The flag
// prevents a duplicate on the initial load.
let initialLoad = true
document.addEventListener("turbo:load", () => {
  if (initialLoad) {
    initialLoad = false
    return
  }
  tracker()?.track()
})

// ── Scroll depth ────────────────────────────────────────────────────────
const DEPTH_MARKS = [25, 50, 75, 100]
let reachedDepths = new Set()
let depthQueued = false

function currentDepth() {
  const doc = document.documentElement
  const scrollable = doc.scrollHeight - window.innerHeight
  if (scrollable <= 0) return 100
  return ((window.scrollY + window.innerHeight) / doc.scrollHeight) * 100
}

function reportDepth() {
  const depth = currentDepth()
  for (const mark of DEPTH_MARKS) {
    if (depth >= mark && !reachedDepths.has(mark)) {
      reachedDepths.add(mark)
      tracker()?.track("scroll-depth", { depth: `${mark}%` })
    }
  }
  if (reachedDepths.size === DEPTH_MARKS.length) {
    window.removeEventListener("scroll", onScroll)
  }
}

function onScroll() {
  if (depthQueued) return
  depthQueued = true
  requestAnimationFrame(() => {
    depthQueued = false
    reportDepth()
  })
}

function resetScrollDepth() {
  reachedDepths = new Set()
  depthQueued = false
  window.addEventListener("scroll", onScroll, { passive: true })
  reportDepth()
}

window.addEventListener("scroll", onScroll, { passive: true })
reportDepth()
document.addEventListener("turbo:load", resetScrollDepth)

// ── Section visibility ──────────────────────────────────────────────────
// Tracks which named sections a visitor scrolls into view. Fires once per
// section per page load. Sections are any element with an id that appears
// on the Getting Started, AI, or component pages.
let seenSections = new Set()
let sectionObserver = null

function observeSections() {
  sectionObserver?.disconnect()
  seenSections = new Set()

  sectionObserver = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        const id = entry.target.id
        if (!entry.isIntersecting || seenSections.has(id)) continue
        seenSections.add(id)
        tracker()?.track("section-view", { section: id, page: location.pathname })
        sectionObserver.unobserve(entry.target)
      }
    },
    { threshold: 0.25, rootMargin: "0px 0px -10% 0px" }
  )

  document.querySelectorAll("section[id], [id='gem'], [id='install'], [id='add'], [id='use']").forEach((el) => {
    sectionObserver.observe(el)
  })
}

document.addEventListener("turbo:load", observeSections)
observeSections()

// ── Install funnel: code block copies ───────────────────────────────────
// The most important conversion signal. Someone copying a gem or generator
// command means they are adopting the kit. The label from the code block
// tells us which command.
const FUNNEL_COMMANDS = {
  "Gemfile": "funnel-add-gem",
  "bundle install": "funnel-bundle-install"
}

document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-action*='clipboard#copy']")
  if (!button) return
  const wrapper = button.closest("[data-controller='clipboard']")
  if (!wrapper) return

  const source = wrapper.querySelector("[data-clipboard-target='source']")
  const text = source?.textContent?.trim() || ""
  const label = wrapper.querySelector(".text-zinc-400")?.textContent?.trim() || ""

  // Identify funnel-critical copies.
  if (FUNNEL_COMMANDS[label]) {
    tracker()?.track(FUNNEL_COMMANDS[label], { command: text })
  } else if (text.startsWith("bin/rails generate velvetkit:install") || text.startsWith("bin/rails g velvetkit:install")) {
    tracker()?.track("funnel-run-install", { command: text })
  } else if (text.startsWith("bin/rails generate velvetkit:add") || text.startsWith("bin/rails g velvetkit:add")) {
    const components = text.replace(/^bin\/rails g(enerate)? velvetkit:add\s*/, "").trim()
    tracker()?.track("funnel-add-component", { components })
  } else {
    tracker()?.track("code-copy", { label: label || "inline", page: location.pathname })
  }
})

// ── External link clicks ────────────────────────────────────────────────
document.addEventListener("click", (event) => {
  const link = event.target.closest('a[target="_blank"]')
  if (!link) return

  const url = link.href
  let name = "external-link"

  if (url.includes("github.com")) name = "click-github"
  else if (url.includes("rubygems.org")) name = "click-rubygems"
  else if (url.includes("kitforge.tech")) name = "click-kitforge"
  else if (url.includes("lookbook.build")) name = "click-lookbook-site"

  tracker()?.track(name, { url })
})

// ── Downloads: llms.txt, llms-full.txt, Markdown ────────────────────────
document.addEventListener("click", (event) => {
  const link = event.target.closest("a[href]")
  if (!link) return
  const href = link.getAttribute("href")

  if (href === "/llms.txt") {
    tracker()?.track("download-llms-txt")
  } else if (href === "/llms-full.txt") {
    tracker()?.track("download-llms-full-txt")
  } else if (href.endsWith(".md")) {
    tracker()?.track("download-markdown", { path: href })
  }
})

// ── Theme toggle ────────────────────────────────────────────────────────
const themeObserver = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
    if (mutation.attributeName === "data-theme") {
      const theme = document.documentElement.dataset.theme || "light"
      tracker()?.track("theme-change", { theme })
    }
  }
})
themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] })

// ── Search ──────────────────────────────────────────────────────────────
document.addEventListener("click", (event) => {
  if (event.target.closest("[data-search-trigger]")) {
    tracker()?.track("search-open")
  }
})

document.addEventListener("click", (event) => {
  const result = event.target.closest("[data-search-target='result']")
  if (!result) return
  tracker()?.track("search-select", {
    query: document.querySelector("[data-search-target='input']")?.value || "",
    result: result.dataset.searchTitle || ""
  })
})

// ── Component filter ────────────────────────────────────────────────────
let filterTimeout = null
document.addEventListener("input", (event) => {
  const input = event.target.closest("[data-action*='filter#filter']")
  if (!input) return
  clearTimeout(filterTimeout)
  filterTimeout = setTimeout(() => {
    const query = input.value.trim()
    if (query.length >= 2) {
      tracker()?.track("component-filter", { query })
    }
  }, 1000)
})

// ── Doc pager navigation ────────────────────────────────────────────────
document.addEventListener("click", (event) => {
  const pagerLink = event.target.closest("nav[aria-label='Pages'] a")
  if (!pagerLink) return
  const direction = pagerLink.querySelector("[name='arrow-left']") ? "previous" : "next"
  tracker()?.track("doc-pager", { direction, page: location.pathname })
})

// ── Namespace playground ────────────────────────────────────────────────
// Tracks when someone types a custom namespace in the playground. This
// means they are thinking about how the kit fits their app.
let namespaceTimeout = null
document.addEventListener("input", (event) => {
  const input = event.target.closest("[data-action*='autosubmit#submit']")
  if (!input || !location.pathname.includes("namespacing")) return
  clearTimeout(namespaceTimeout)
  namespaceTimeout = setTimeout(() => {
    const value = input.value.trim()
    if (value) {
      tracker()?.track("playground-namespace", { namespace: value })
    }
  }, 1500)
})

// ── Theming playground ──────────────────────────────────────────────────
// Tracks when someone adjusts the theming sliders. Fires once per page
// load after the first interaction, not on every slider move.
let themingTracked = false
document.addEventListener("input", (event) => {
  if (themingTracked) return
  const slider = event.target.closest("[data-action*='theme-playground#update']")
  if (!slider) return
  themingTracked = true
  tracker()?.track("playground-theming")
})
document.addEventListener("turbo:load", () => { themingTracked = false })

// ── FAQ accordion ───────────────────────────────────────────────────────
// Tracks which FAQ questions people open. Shows evaluation concerns.
document.addEventListener("click", (event) => {
  const trigger = event.target.closest("[data-action*='accordion']")
  if (!trigger) return
  const text = trigger.textContent?.trim()
  if (text && text.endsWith("?")) {
    tracker()?.track("faq-open", { question: text })
  }
})

// ── Hero showcase rail ──────────────────────────────────────────────────
// Tracks arrow button clicks on the home page showcase rail. Scrolling
// the rail with touch or mouse wheel is not tracked (too noisy).
document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-action*='rail#']")
  if (!button) return
  const direction = button.dataset.action.includes("previous") ? "back" : "forward"
  tracker()?.track("showcase-rail", { direction })
})

// ── Sidebar navigation clicks (docs) ────────────────────────────────────
document.addEventListener("click", (event) => {
  const link = event.target.closest("nav[aria-label='Documentation'] a")
  if (!link) return
  tracker()?.track("sidebar-nav", { target: link.textContent?.trim(), from: location.pathname })
})
