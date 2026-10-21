// Carries the focus ring across Turbo visits.
//
// The ring on a clicked link is VelvetKit's signature, but Turbo swaps the
// page in and the clicked link goes with it, so the ring vanished part way
// through the visit. When a link inside a [data-focus-scope] area (the
// header nav, the docs sidebar) is clicked, the same link in the same area
// of the new page is focused once it loads, and the ring stays put.
let carried = null

document.addEventListener("turbo:click", (event) => {
  const link = event.target.closest("a[href]")
  const scope = link?.closest("[data-focus-scope]")
  carried = scope ? { href: link.getAttribute("href"), scope: scope.dataset.focusScope } : null
})

document.addEventListener("turbo:load", () => {
  if (!carried) return
  const { href, scope } = carried
  carried = null

  const area = document.querySelector(`[data-focus-scope="${scope}"]`)
  const link = area && [...area.querySelectorAll("a[href]")].find((a) => a.getAttribute("href") === href)
  link?.focus({ preventScroll: true })
})
