import { Controller } from "@hotwired/stimulus"

// Retints the components inside the stage by overriding the kit's tokens on
// it, and writes out the CSS that would do the same for a whole app.
export default class extends Controller {
  static targets = ["stage", "hue", "radius", "hueValue", "radiusValue", "css"]

  connect() {
    this.update()
  }

  update() {
    const hue = this.hueTarget.value
    const radius = (this.radiusTarget.value / 100).toFixed(2)
    const primary = `oklch(0.55 0.19 ${hue})`

    this.stageTarget.style.setProperty("--primary", primary)
    this.stageTarget.style.setProperty("--ring", primary)
    this.stageTarget.style.setProperty("--radius", `${radius}rem`)
    this.hueValueTarget.textContent = hue
    this.radiusValueTarget.textContent = `${radius}rem`
    this.cssTarget.textContent = `:root {\n  --primary: ${primary};\n  --ring: ${primary};\n  --radius: ${radius}rem;\n}`
  }
}
