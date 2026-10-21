import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--password-visibility"
//
// Toggles a password field between masked and plain text, swapping the
// eye/eye-off icons and keeping the trigger's accessible name and pressed
// state in sync so screen readers announce the change.
export default class extends Controller<HTMLElement> {
  static targets = ['input', 'toggle', 'iconShow', 'iconHide'];

  declare readonly hasInputTarget: boolean;
  declare readonly hasToggleTarget: boolean;
  declare readonly hasIconShowTarget: boolean;
  declare readonly hasIconHideTarget: boolean;
  declare readonly inputTarget: HTMLInputElement;
  declare readonly toggleTarget: HTMLElement;
  declare readonly iconShowTarget: HTMLElement;
  declare readonly iconHideTarget: HTMLElement;

  toggle(event?: Event) {
    event?.preventDefault();
    if (!this.hasInputTarget) return;

    const revealed = this.inputTarget.type === 'text';
    this.inputTarget.type = revealed ? 'password' : 'text';
    this.sync(!revealed);
  }

  private sync(revealed: boolean) {
    // Inline styles, to match the server-rendered initial state and to stay
    // immune to any competing display utility.
    if (this.hasIconShowTarget) this.iconShowTarget.style.display = revealed ? 'none' : '';
    if (this.hasIconHideTarget) this.iconHideTarget.style.display = revealed ? '' : 'none';

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute('aria-pressed', revealed ? 'true' : 'false');
      this.toggleTarget.setAttribute(
        'aria-label',
        revealed ? 'Hide password' : 'Show password',
      );
    }
  }
}
