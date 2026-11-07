import { track } from "./analytics"

// How far down a page people get, and which of the home page's sections they
// see. Each counts once per page view. A page that fits the window has no depth
// to report, and nothing is reported until someone actually scrolls.
const DEPTHS = [50, 90]

const reached = new Set()
let observer
let queued = false

function reportDepth() {
  queued = false
  const { scrollHeight } = document.documentElement
  if (scrollHeight <= window.innerHeight) return

  const percent = (window.scrollY + window.innerHeight) / scrollHeight * 100
  DEPTHS.filter((depth) => percent >= depth && !reached.has(depth)).forEach((depth) => {
    reached.add(depth)
    track("scroll_depth", { depth })
  })
}

function watchSections() {
  observer?.disconnect()
  observer = new IntersectionObserver((entries) => {
    entries.filter((entry) => entry.isIntersecting).forEach((entry) => {
      observer.unobserve(entry.target)
      track("section_view", { section: entry.target.dataset.analyticsSection })
    })
  })
  document.querySelectorAll("[data-analytics-section]").forEach((section) => observer.observe(section))
}

document.addEventListener("scroll", () => {
  if (queued) return
  queued = true
  requestAnimationFrame(reportDepth)
}, { passive: true })

document.addEventListener("turbo:load", () => {
  reached.clear()
  watchSections()
})
