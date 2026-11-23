import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--rating"
//
// Each half-star is the label of a radio, and CSS fills the stars up to the
// checked one. This only previews: over a half-star, it lights that half and
// the ones before it; leaving the stars, or choosing one, hands them back.
export default class extends Controller<HTMLElement> {
  static targets = ['star'];

  declare readonly starTargets: HTMLLabelElement[];

  preview(event: MouseEvent) {
    const star = event.currentTarget as HTMLLabelElement;
    if ((star.control as HTMLInputElement | null)?.disabled) return;

    const value = Number(star.dataset.value);
    this.starTargets.forEach((each) => {
      each.dataset.lit = String(Number(each.dataset.value) <= value);
    });
  }

  reset() {
    for (const star of this.starTargets) delete star.dataset.lit;
  }
}
