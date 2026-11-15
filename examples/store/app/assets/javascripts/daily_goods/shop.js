// The shop's two bits of JavaScript: filters and the cart.
//
// Sends the shop's filter form when any control in it changes, so the
// products update as you choose. Some controls exist twice, in the page and
// in the phone sheet: each copy sits in a fieldset with a media query, and
// only the copy on show is sent.
let timer

const sync = (form) => {
  form.querySelectorAll("fieldset[data-media]").forEach((scope) => {
    scope.disabled = !window.matchMedia(scope.dataset.media).matches
  })
}

document.addEventListener("change", (event) => {
  const form = event.target.closest?.("form[data-shop-filters]")
  if (!form) return

  clearTimeout(timer)
  timer = setTimeout(() => {
    sync(form)
    form.requestSubmit()
  }, 150)
})


// Cart forms are sent here rather than by Turbo, which runs one page-level
// form at a time and cancels the one on its way when another starts: two
// quick clicks would lose one. These go one after another, and each answer's
// Turbo Streams update the badge and the cart sheet.
let queue = Promise.resolve()

document.addEventListener("submit", (event) => {
  const form = event.target
  if (!(form instanceof HTMLFormElement) || !form.matches("[data-cart]") || !window.Turbo) return

  event.preventDefault()
  const body = new FormData(form, event.submitter)
  queue = queue.then(async () => {
    try {
      const response = await fetch(form.action, {
        method: "POST",
        body,
        headers: { Accept: "text/vnd.turbo-stream.html" },
        credentials: "same-origin"
      })
      if (response.ok) window.Turbo.renderStreamMessage(await response.text())
    } catch {
      // Offline or the server didn't answer: the cart is left as it was.
    }
  })
}, true)
