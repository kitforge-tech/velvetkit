// The docs' examples post to /demo/ paths (the Confirm dialog's, for one).
// Stop those requests before they leave and say what would have happened,
// so trying an example never changes anything or lands on a 404. A form
// marked data-demo-live talks to a real demo endpoint (ScanInput's till), so
// it's let through.
import { toast } from "./controllers/ui/toast_viewport_controller"

document.addEventListener("turbo:before-fetch-request", (event) => {
  const { url, fetchOptions } = event.detail
  if (!url.pathname.startsWith("/demo/")) return
  if (event.target instanceof Element && event.target.closest("[data-demo-live]")) return

  event.preventDefault()
  const method = (fetchOptions.body?.get?.("_method") || fetchOptions.method || "get").toUpperCase()
  toast("Confirmed", { description: `This would send ${method} ${url.pathname}. It's a demo, so nothing changed.`, variant: "success" })
})
