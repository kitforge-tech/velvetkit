import { Controller } from "@hotwired/stimulus"

// Retints the components inside the stage by overriding the kit's tokens on
// it, and writes out the CSS that would do the same for a whole app.
//
// Until a slider moves, the stage shows the real tokens: the sliders start at
// velvet's hue and radius, but the light and dark themes use different
// lightness, which one override can't match.
export default class extends Controller {
  static targets = ["stage", "hue", "radius", "hueValue", "radiusValue", "css"]

  connect() {
    this.describe()
  }

  update() {
    const { primary, radius } = this.values()
    this.stageTarget.style.setProperty("--primary", primary)
    this.stageTarget.style.setProperty("--ring", primary)
    this.stageTarget.style.setProperty("--radius", radius)
    this.describe()
  }

  describe() {
    const { hue, primary, radius } = this.values()
    this.hueValueTarget.textContent = hue
    this.radiusValueTarget.textContent = radius
    this.cssTarget.textContent = `:root {\n  --primary: ${primary};\n  --ring: ${primary};\n  --radius: ${radius};\n}`
  }

  values() {
    const hue = this.hueTarget.value
    return { hue, primary: `oklch(0.45 0.17 ${hue})`, radius: `${(this.radiusTarget.value / 100).toFixed(2)}rem` }
  }
}
