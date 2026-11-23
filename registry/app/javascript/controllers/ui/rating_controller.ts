import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--rating"
//
// Each half-star is the label of a radio, and CSS fills the stars up to the
// checked one. Over a half-star, this lights that half and the ones before it,
// and grows the star it's in; leaving the stars, or choosing one, hands them
// back. It also gives the choice some feedback: the focused radio's star is
// outlined, and a chosen star settles back to size, or pops when chosen from
// the keyboard. Choosing also clears the field's error, if it has one, and
// shows its thanks, if it has those; resetting the form brings them back as
// they were.
export default class extends Controller<HTMLElement> {
  static targets = ['star'];
  static values = { error: String, thanks: String };

  declare readonly starTargets: HTMLLabelElement[];
  declare readonly errorValue: string;
  declare readonly thanksValue: string;

  // The star just chosen under the pointer, kept at its size until the
  // pointer moves to another.
  private settled: number | null = null;

  preview(event: MouseEvent) {
    const star = event.currentTarget as HTMLLabelElement;
    if ((star.control as HTMLInputElement | null)?.disabled) return;

    const value = Number(star.dataset.value);
    this.starTargets.forEach((each) => {
      each.dataset.lit = String(Number(each.dataset.value) <= value);
    });

    const whole = Math.ceil(value);
    if (whole !== this.settled) this.settled = null;
    this.mark('hovered', this.settled === null ? this.halvesOf(whole) : []);
  }

  reset() {
    for (const star of this.starTargets) delete star.dataset.lit;
    this.mark('hovered', []);
    this.settled = null;
  }

  choose(event: Event) {
    const input = event.target as HTMLInputElement;
    const whole = Math.ceil(Number(input.value));
    const halves = this.halvesOf(whole);

    for (const star of this.starTargets) delete star.dataset.lit;
    if (document.activeElement === input) this.mark('focused', halves);

    if (halves.some((half) => half.dataset.hovered)) {
      this.mark('hovered', []);
      this.settled = whole;
    } else {
      this.pop(halves);
    }

    this.showAnswered(true);
  }

  // Arrow keys move focus along with the choice, so this follows them too.
  focus(event: FocusEvent) {
    this.mark('focused', this.halvesOf(Math.ceil(Number((event.target as HTMLInputElement).value))));
  }

  blur(event: FocusEvent) {
    if (!this.element.contains(event.relatedTarget as Node | null)) this.mark('focused', []);
  }

  // The form's reset puts the radios back; this puts back the rest.
  formReset(event: Event) {
    if (!(event.target as Node).contains(this.element)) return;

    this.reset();
    this.mark('focused', []);
    this.showAnswered(false);
  }

  // Answered, the error's hidden and gone from what the group says about
  // itself, and the thanks, which are a status, are read out as they show.
  private showAnswered(answered: boolean) {
    const error = this.errorValue && document.getElementById(this.errorValue);
    if (error) {
      error.hidden = answered;
      const group = this.element.closest('[role="radiogroup"]');
      const others = (group?.getAttribute('aria-describedby') ?? '').split(' ').filter((id) => id && id !== this.errorValue);
      const describedby = answered ? others : [...others, this.errorValue];
      if (answered) group?.removeAttribute('aria-invalid');
      else group?.setAttribute('aria-invalid', 'true');
      if (describedby.length) group?.setAttribute('aria-describedby', describedby.join(' '));
      else group?.removeAttribute('aria-describedby');
    }

    const thanks = this.thanksValue && document.getElementById(this.thanksValue);
    if (thanks) thanks.hidden = !answered;
  }

  // Both half-star labels of a whole star.
  private halvesOf(whole: number) {
    return this.starTargets.filter((each) => Math.ceil(Number(each.dataset.value)) === whole);
  }

  private mark(key: 'focused' | 'hovered', halves: HTMLLabelElement[]) {
    for (const star of this.starTargets) {
      if (halves.includes(star)) star.dataset[key] = 'true';
      else delete star.dataset[key];
    }
  }

  private pop(halves: HTMLLabelElement[]) {
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    for (const half of halves) {
      half.animate([1, 1.25, 1].map((scale) => ({ transform: `scale(${scale})` })), {
        duration: 250,
        easing: 'ease-out',
      });
    }
  }
}
