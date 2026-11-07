// Reports to the page analytics, when the tracker has loaded. It may never:
// it's optional, and blocked in many browsers.
export const track = (name, data) => window.umami?.track(name, data)

// Text that could identify someone: an email address, a card or phone number, a
// date. Digits count however they're split up, so 06-12-34 is caught too.
export const looksPersonal = (text) => text.includes("@") || text.replace(/\D/g, "").length >= 4

// A search query fit to report, or null. Anything that looks personal stays in
// the browser.
export function cleanQuery(raw) {
  const query = raw.trim().toLowerCase().replace(/\s+/g, " ")
  if (query.length < 2 || query.length > 40) return null
  if (looksPersonal(query)) return null
  return query
}

// Reports a search that found nothing, once the typing has settled, so a word
// half typed doesn't count. The same query twice in a row counts once.
export function missReporter(source) {
  let timer
  let last

  const cancel = () => clearTimeout(timer)
  const report = (raw) => {
    cancel()
    timer = setTimeout(() => {
      const query = cleanQuery(raw)
      if (!query || query === last) return
      last = query
      track("search_miss", { query, source })
    }, 1500)
  }

  return { report, cancel }
}
