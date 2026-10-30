import { Controller } from '@hotwired/stimulus';

// Matches the exit animation's `duration-300` in UI::Toast (and its
// EXIT_DURATION constant). Removing on a fixed timer, rather than the exit
// animation's `animationend`, sidesteps a real race: a toast dismissed while
// its own *entrance* animation is still playing would otherwise have its
// entrance's animationend fire moments later and remove the element early,
// before the exit animation ever got a chance to play.
const EXIT_DURATION = 300;

/**
 * UI::Toast controller — owns one toast's lifecycle, however it arrived
 * (rendered by ERB, appended by a Turbo Stream, or cloned by the
 * toast-viewport controller from its templates).
 *
 * Auto-dismisses after durationValue ms, pausing while the pointer is over
 * it. durationValue of 0 means "stays until dismissed".
 */
export default class extends Controller<HTMLElement> {
  static values = { duration: { type: Number, default: 5000 } };

  declare durationValue: number;

  private timeout: number | null = null;

  connect() {
    this.arm();
  }

  disconnect() {
    this.disarm();
  }

  pause() {
    this.disarm();
  }

  resume() {
    this.arm();
  }

  dismiss = (event?: Event) => {
    event?.preventDefault();
    this.disarm();
    if (this.element.dataset.state === 'closed') return;
    this.element.dataset.state = 'closed';
    window.setTimeout(() => this.element.remove(), EXIT_DURATION);
  };

  private arm() {
    this.disarm();
    if (!this.durationValue) return;
    this.timeout = window.setTimeout(this.dismiss, this.durationValue);
  }

  private disarm() {
    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
  }
}
