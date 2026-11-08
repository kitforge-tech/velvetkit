import { track } from "./analytics"

// How far down a page people get, and which of the home page's sections they
// see. Each counts once per page view, which means a new path: the analytics
// ignore query strings, so a frame visit on the same path is the same view. A
// page that fits the window has no depth to report.
//
// Turbo moves the page itself on a visit (to the top, or back where it was), and
// the browser sends that scroll a frame later, so scrolls count only once two
// frames have passed.
const DEPTHS = [50, 90]

const reached = new Set()
let observer
let path
let armed = false
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
  if (!armed || queued) return
  queued = true
  requestAnimationFrame(reportDepth)
}, { passive: true })

document.addEventListener("turbo:load", () => {
  armed = false
  requestAnimationFrame(() => requestAnimationFrame(() => { armed = true }))

  if (window.location.pathname === path) return
  path = window.location.pathname
  reached.clear()
  watchSections()
})
