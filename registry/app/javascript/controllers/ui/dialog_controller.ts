import { Controller } from '@hotwired/stimulus';

/**
 * UI::Dialog controller — opens and closes a native <dialog> via showModal().
 *
 * What we DO:
 *   - open()  : trigger.click → dialog.showModal() → set data-state=open
 *   - close() : close-button.click or backdrop click → dialog.close()
 *
 * What we DELEGATE TO THE PLATFORM:
 *   - modal mode, inert background, return focus, focus trap, ESC dismissal —
 *     all handled by <dialog>.showModal() natively.
 */
export default class extends Controller<HTMLElement> {
  static targets = ['trigger', 'content'];

  declare readonly hasTriggerTarget: boolean;
  declare readonly triggerTarget: HTMLElement;
  declare readonly contentTarget: HTMLDialogElement;

  connect() {
    this.contentTarget.addEventListener('close', this.handleClose);
    this.contentTarget.addEventListener('cancel', this.handleCancel);
    this.contentTarget.addEventListener('click', this.handleBackdropClick);
  }

  disconnect() {
    this.contentTarget.removeEventListener('close', this.handleClose);
    this.contentTarget.removeEventListener('cancel', this.handleCancel);
    this.contentTarget.removeEventListener('click', this.handleBackdropClick);
    if (this.contentTarget.open) this.contentTarget.close();
  }

  open(event?: Event) {
    event?.preventDefault();
    if (this.contentTarget.open) return;
    this.contentTarget.showModal();
    this.setState('open');
  }

  close(event?: Event) {
    event?.preventDefault();
    if (this.contentTarget.open) this.contentTarget.close();
  }

  // Native `cancel` fires on ESC. Let the default close happen, just sync
  // state via the close listener.
  private handleCancel = (_event: Event) => {
    /* noop — close listener handles state */
  };

  private handleClose = () => {
    this.setState('closed');
  };

  // Click outside the panel = click on the dialog element itself (because the
  // panel is a child of the dialog). Close in that case.
  private handleBackdropClick = (event: MouseEvent) => {
    if (event.target === this.contentTarget) this.close();
  };

  private setState(state: 'open' | 'closed') {
    this.contentTarget.dataset.state = state;
    const panel = this.contentTarget.querySelector<HTMLElement>('[data-ui--dialog-part="panel"]');
    if (panel) panel.dataset.state = state;
    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute('aria-expanded', state === 'open' ? 'true' : 'false');
    }
  }
}
