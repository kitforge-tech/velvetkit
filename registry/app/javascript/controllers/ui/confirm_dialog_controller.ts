import { Controller } from '@hotwired/stimulus';

type ConfirmMethod = (message: string, element: HTMLFormElement, submitter?: HTMLElement | null) => Promise<boolean>;

interface TurboGlobal {
  config?: { forms?: { confirm?: ConfirmMethod } };
  setConfirmMethod?: (method: ConfirmMethod) => void;
}

/**
 * UI::ConfirmDialog controller — answers Turbo's data-turbo-confirm with a
 * native <dialog> instead of window.confirm().
 *
 * The confirm and cancel buttons submit a method="dialog" form, so the
 * browser closes the dialog and sets its returnValue; Escape closes it with
 * an empty one. Either way the `close` event resolves Turbo's promise.
 *
 * Turbo copies only data-turbo-confirm when it turns a data-turbo-method link
 * into a form, so the other data-confirm-* options are also looked up on the
 * element that was last clicked.
 */
export default class extends Controller<HTMLDialogElement> {
  static targets = ['panel', 'title', 'description', 'cancel', 'confirm', 'destructive'];
  static values = { confirmLabel: String, cancelLabel: String };

  declare readonly panelTarget: HTMLElement;
  declare readonly titleTarget: HTMLElement;
  declare readonly descriptionTarget: HTMLElement;
  declare readonly cancelTarget: HTMLButtonElement;
  declare readonly confirmTarget: HTMLButtonElement;
  declare readonly destructiveTarget: HTMLButtonElement;
  declare confirmLabelValue: string;
  declare cancelLabelValue: string;

  private previous?: ConfirmMethod;
  private clicked: Element | null = null;
  private resolve?: (answer: boolean) => void;

  connect() {
    document.addEventListener('click', this.remember, true);
    this.element.addEventListener('close', this.closed);
    this.element.addEventListener('click', this.backdropClick);

    const turbo = (window as unknown as { Turbo?: TurboGlobal }).Turbo;
    if (turbo?.config?.forms) {
      this.previous = turbo.config.forms.confirm;
      turbo.config.forms.confirm = this.confirm;
    } else {
      turbo?.setConfirmMethod?.(this.confirm);
    }
  }

  disconnect() {
    document.removeEventListener('click', this.remember, true);
    this.element.removeEventListener('close', this.closed);
    this.element.removeEventListener('click', this.backdropClick);

    const turbo = (window as unknown as { Turbo?: TurboGlobal }).Turbo;
    if (turbo?.config?.forms && turbo.config.forms.confirm === this.confirm) {
      turbo.config.forms.confirm = this.previous;
    }
    this.answer(false);
    if (this.element.open) this.element.close();
  }

  confirm = (message: string, form: HTMLFormElement, submitter?: HTMLElement | null): Promise<boolean> => {
    this.answer(false);
    const sources = [submitter, form, this.clicked?.getAttribute('data-turbo-confirm') === message ? this.clicked : null];
    const option = (name: string) =>
      sources.find((el) => el?.hasAttribute(`data-confirm-${name}`))?.getAttribute(`data-confirm-${name}`) ?? null;

    this.titleTarget.textContent = message;
    const description = option('description');
    this.descriptionTarget.textContent = description ?? '';
    this.descriptionTarget.hidden = !description;

    const destructive = option('variant') === 'destructive';
    const label = option('button') ?? this.confirmLabelValue;
    this.confirmTarget.hidden = destructive;
    this.destructiveTarget.hidden = !destructive;
    this.confirmTarget.textContent = label;
    this.destructiveTarget.textContent = label;
    this.cancelTarget.textContent = option('cancel') ?? this.cancelLabelValue;

    this.element.returnValue = '';
    this.element.showModal();
    this.panelTarget.dataset.state = 'open';
    this.cancelTarget.focus();

    return new Promise((resolve) => (this.resolve = resolve));
  };

  private remember = (event: Event) => {
    this.clicked = (event.target as Element | null)?.closest?.('[data-turbo-confirm]') ?? null;
  };

  private backdropClick = (event: MouseEvent) => {
    if (event.target === this.element) this.element.close('cancel');
  };

  private closed = () => {
    this.panelTarget.dataset.state = 'closed';
    this.answer(this.element.returnValue === 'confirm');
  };

  private answer(value: boolean) {
    this.resolve?.(value);
    this.resolve = undefined;
  }
}
