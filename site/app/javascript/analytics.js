// Umami event tracking for the VelvetKit docs site.
// The tracker script itself loads in the layout. This module adds:
// - Turbo-aware page views (no double-count on initial load)
// - Scroll depth reporting (25/50/75/100%)
// - Section visibility on the home page
// - Code block copy tracking
// - Search, theme toggle, and outbound link tracking

const tracker = () => window.umami

// ---------------------------------------------------------------------------
// Turbo page views
// ---------------------------------------------------------------------------
// Umami's script.js fires a page view on DOMContentLoaded. Turbo replaces the
// body without a full load, so subsequent navigations need an explicit call.
// We skip the first turbo:load to avoid a double count.

let firstLoad = true

document.addEventListener("turbo:load", () => {
  if (firstLoad) { firstLoad = false; return }
  tracker()?.track()
})

// ---------------------------------------------------------------------------
// Scroll depth
// ---------------------------------------------------------------------------

const DEPTH_MARKS = [25, 50, 75, 100]
let reachedDepths = new Set()
let scrollQueued = false

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
  if (scrollQueued) return
  scrollQueued = true
  requestAnimationFrame(() => {
    scrollQueued = false
    reportDepth()
  })
}

function initScrollDepth() {
  reachedDepths = new Set()
  window.removeEventListener("scroll", onScroll)
  window.addEventListener("scroll", onScroll, { passive: true })
  reportDepth()
}

initScrollDepth()
document.addEventListener("turbo:load", initScrollDepth)

// ---------------------------------------------------------------------------
// Home page section visibility
// ---------------------------------------------------------------------------

const HOME_SECTIONS = ["how-it-works", "features", "components-showcase"]
let sectionObserver = null

function initSectionVisibility() {
  if (sectionObserver) { sectionObserver.disconnect(); sectionObserver = null }
  if (window.location.pathname !== "/") return

  const seen = new Set()
  sectionObserver = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        const id = entry.target.id
        if (!entry.isIntersecting || seen.has(id)) continue
        seen.add(id)
        tracker()?.track(`section-${id}`)
        sectionObserver.unobserve(entry.target)
      }
    },
    { threshold: 0.25, rootMargin: "0px 0px -10% 0px" }
  )

  for (const id of HOME_SECTIONS) {
    const el = document.getElementById(id)
    if (el) sectionObserver.observe(el)
  }
}

document.addEventListener("turbo:load", initSectionVisibility)
initSectionVisibility()

// ---------------------------------------------------------------------------
// Code block copy tracking
// ---------------------------------------------------------------------------
// The clipboard controller dispatches clipboard#copy via Stimulus. We listen
// for the copy event on any code block's copy button. Because the button uses
// data-action="clipboard#copy", we can catch the click before Stimulus does.

document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-action*='clipboard#copy']")
  if (!button) return

  const block = button.closest("[data-controller='clipboard']")
  if (!block) return

  const label = block.querySelector(".text-zinc-400")?.textContent?.trim()
  tracker()?.track("code-copy", { label: label || "unlabelled" })
})

// ---------------------------------------------------------------------------
// "Ask AI" menu and "Open in" links
// ---------------------------------------------------------------------------

document.addEventListener("click", (event) => {
  const link = event.target.closest("a")
  if (!link) return
  const href = link.getAttribute("href") || ""

  if (href.startsWith("https://claude.ai/")) {
    tracker()?.track("open-in-ai", { assistant: "Claude" })
  } else if (href.startsWith("https://chatgpt.com/")) {
    tracker()?.track("open-in-ai", { assistant: "ChatGPT" })
  }
})

// ---------------------------------------------------------------------------
// Search usage
// ---------------------------------------------------------------------------
// Track when the search dialog opens and when a result is selected.

let searchTracked = false

const searchObserver = new MutationObserver(() => {
  const dialog = document.querySelector("[data-controller='search']")
  if (dialog && !searchTracked) {
    searchTracked = true
    tracker()?.track("search-open")
  } else if (!dialog) {
    searchTracked = false
  }
})

searchObserver.observe(document.body, { childList: true, subtree: true })

document.addEventListener("click", (event) => {
  const result = event.target.closest("[data-search-target='result']")
  if (!result) return
  const title = result.dataset.searchTitle || result.textContent.trim()
  tracker()?.track("search-select", { title })
})

// ---------------------------------------------------------------------------
// Theme toggle
// ---------------------------------------------------------------------------

document.addEventListener("click", (event) => {
  const toggle = event.target.closest("[data-action*='theme#toggle'], [data-action*='theme#set']")
  if (!toggle) return
  requestAnimationFrame(() => {
    const theme = document.documentElement.dataset.theme || "system"
    tracker()?.track("theme-change", { theme })
  })
})

// ---------------------------------------------------------------------------
// Outbound links
// ---------------------------------------------------------------------------

document.addEventListener("click", (event) => {
  const link = event.target.closest("a[href^='http']")
  if (!link) return
  if (link.hostname === window.location.hostname) return

  tracker()?.track("outbound-link", {
    url: link.href,
    text: link.textContent.trim().substring(0, 80)
  })
})

// ---------------------------------------------------------------------------
// LLM file downloads (llms.txt, llms-full.txt, .md exports)
// ---------------------------------------------------------------------------

document.addEventListener("click", (event) => {
  const link = event.target.closest("a")
  if (!link) return
  const href = link.getAttribute("href") || ""

  if (href.includes("/llms.txt")) {
    tracker()?.track("llm-download", { file: "llms.txt" })
  } else if (href.includes("/llms-full.txt")) {
    tracker()?.track("llm-download", { file: "llms-full.txt" })
  } else if (href.endsWith(".md")) {
    tracker()?.track("llm-download", { file: href })
  }
})
