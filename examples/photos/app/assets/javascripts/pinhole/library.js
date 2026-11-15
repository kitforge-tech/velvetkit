// Pinhole's own behaviour, on top of the kit's components.

// While photos are being chosen, clicking a photo chooses it too, rather than
// opening it, the way photo apps do. Shift-click still chooses a run.
document.addEventListener("click", (event) => {
  const trigger = event.target.closest("[data-ui--gallery-target=trigger]")
  const grid = trigger?.closest("[data-selecting]")
  if (!trigger || !grid) return

  const box = trigger.parentElement.querySelector("[data-selection=item]")
  if (!box) return

  event.preventDefault()
  event.stopPropagation()
  box.dispatchEvent(new MouseEvent("click", { bubbles: true, shiftKey: event.shiftKey }))
}, true)

// A button in the photo viewer that changes the page (Move to bin) closes the
// viewer first, so the page underneath can be refreshed.
document.addEventListener("turbo:submit-start", (event) => {
  const dialog = event.target.closest("dialog[open]")
  if (dialog && !event.target.matches("[data-turbo-stream]")) dialog.close()
})
