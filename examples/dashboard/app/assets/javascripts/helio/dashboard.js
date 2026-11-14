// Helio's one bit of its own JavaScript: a form marked data-auto-submit (the
// Overview's period picker) sends itself when a control in it changes.
document.addEventListener("change", (event) => {
  const form = event.target.closest?.("form[data-auto-submit]")
  if (form) form.requestSubmit()
})
