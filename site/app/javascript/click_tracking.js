import { looksPersonal, track } from "./analytics"

// Which controls get clicked, across the whole site. It only watches, so a click
// goes on to do what it always did. It reports what a control says, never what's
// been typed into one. Live demos report no text at all: what their controls say
// can be what a visitor typed, like a tab they've renamed.
const ROLES = [ "button", "link", "tab", "menuitem", "menuitemcheckbox", "menuitemradio", "option", "switch", "checkbox", "radio" ]
const INPUTS = [ "checkbox", "radio", "submit", "button" ]
const CLICKABLE = [
  "a[href]", "button", "summary",
  ...INPUTS.map((type) => `input[type=${type}]`),
  ...ROLES.map((role) => `[role=${role}]`)
].join(",")

// Pages can have a header or footer of their own, so the site's are matched
// from the body. The first that fits wins: a dialog in a demo is a demo click.
const AREAS = [
  [ "[data-outline-skip]", "demo" ],
  [ "dialog", "dialog" ],
  [ "body > header", "header" ],
  [ "body > footer", "footer" ],
  [ "aside", "sidebar" ],
  [ "main", "main" ]
]

function element(control) {
  if (control.getAttribute("role")) return control.getAttribute("role")
  if (control.matches("a")) return "link"
  return control.matches("input") ? control.type : control.localName
}

function label(control) {
  const text = control.getAttribute("aria-label") || control.labels?.[0]?.textContent || control.textContent
  const clean = text.trim().replace(/\s+/g, " ").slice(0, 50)
  return looksPersonal(clean) ? "(hidden)" : clean
}

function area(control) {
  const marked = control.closest("[data-analytics-area]")?.dataset.analyticsArea
  return marked ?? AREAS.find(([ selector ]) => control.closest(selector))?.[1] ?? "page"
}

// The path of a link on this site, the host of any other. Query strings stay
// out: the Ask AI links carry a whole prompt in theirs.
function destination(link) {
  const url = new URL(link.getAttribute("href"), window.location.href)
  return url.origin === window.location.origin ? url.pathname : url.hostname
}

function describeClick(target) {
  const control = target.closest?.(CLICKABLE)
  if (!control || control.disabled || control.getAttribute("aria-disabled") === "true") return null

  const where = area(control)
  const data = { element: element(control), label: where === "demo" ? "(demo)" : label(control), area: where }
  if (control.matches("a[href]")) data.href = destination(control)
  return data
}

document.addEventListener("click", (event) => {
  const data = describeClick(event.target)
  if (data) track("ui_click", data)
}, true)
