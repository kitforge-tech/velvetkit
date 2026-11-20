import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--rating"
//
// Each star is the label of a radio, and CSS fills the stars up to the
// checked one. This only previews: over a star, it lights that star and the
// ones before it; leaving the stars, or choosing one, hands them back.
export default class extends Controller<HTMLElement> {
  static targets = ['star'];

  declare readonly starTargets: HTMLLabelElement[];

  preview(event: MouseEvent) {
    const star = event.currentTarget as HTMLLabelElement;
    if ((star.control as HTMLInputElement | null)?.disabled) return;

    const index = this.starTargets.indexOf(star);
    this.starTargets.forEach((each, i) => {
      each.dataset.lit = String(i <= index);
    });
  }

  reset() {
    for (const star of this.starTargets) delete star.dataset.lit;
  }
}
