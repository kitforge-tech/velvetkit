import { Controller } from '@hotwired/stimulus';

type Status = 'complete' | 'current' | 'upcoming' | 'error' | 'loading';

// Moves a UI::Stepper between its steps in the browser. Every step's look hangs
// off its data-status, so this sets that, aria-current, and which panel shows.
// Moving on checks the current panel's fields first; an invalid one keeps
// someone on the step and marks it as an error until it's fixed.
export default class extends Controller<HTMLElement> {
  static targets = ['step', 'panel', 'completion', 'previous', 'next', 'submit', 'summary'];
  static values = { current: { type: Number, default: 1 }, summary: String };

  declare readonly stepTargets: HTMLElement[];
  declare readonly panelTargets: HTMLElement[];
  declare readonly completionTargets: HTMLElement[];
  declare readonly previousTargets: HTMLButtonElement[];
  declare readonly nextTargets: HTMLElement[];
  declare readonly submitTargets: HTMLElement[];
  declare readonly summaryTargets: HTMLElement[];
  declare currentValue: number;
  declare summaryValue: string;

  connect() {
    // The server drew the steps as they are; only the buttons need setting.
    this.syncButtons();
  }

  next() {
    if (this.currentValue > this.total) return;
    if (!this.validate()) return;
    this.go(this.currentValue + 1);
  }

  previous() {
    if (this.currentValue > 1) this.go(this.currentValue - 1);
  }

  reset() {
    this.go(1);
  }

  // data-action="ui--stepper#goTo" data-ui--stepper-step-param="2". Going on
  // past the current step still checks each panel on the way.
  goTo(event: Event & { params: { step?: number | string } }) {
    const step = Number(event.params.step);
    if (!(step >= 1 && step <= this.total + 1)) return;
    while (this.currentValue < step) {
      if (!this.validate()) return;
      this.go(this.currentValue + 1);
    }
    if (step < this.currentValue) this.go(step);
  }

  // Enter in a field moves on, rather than submitting the form underneath from
  // the first step. On the last step it submits as usual.
  keydown(event: KeyboardEvent) {
    const field = event.target as HTMLElement;
    if (event.key !== 'Enter' || !(field instanceof HTMLInputElement)) return;
    if (!this.panelTargets.length || this.currentValue >= this.total) return;
    if (!this.currentPanel?.contains(field)) return;
    event.preventDefault();
    this.next();
  }

  // Back to plain "current" once an invalid panel's fields are all valid.
  revalidate() {
    const step = this.currentStep;
    if (step?.dataset.status !== 'error' || !this.currentPanel) return;
    if (this.fields(this.currentPanel).every((field) => field.checkValidity())) this.setStatus(step, 'current');
  }

  // A form inside the stepper being checked on the server: a spinner on the
  // step until the answer comes back and replaces the stepper, or fails.
  submitting() {
    const step = this.currentStep;
    if (step) this.setStatus(step, 'loading');
  }

  submitted(event: CustomEvent<{ success: boolean }>) {
    const step = this.currentStep;
    if (step?.dataset.status === 'loading') this.setStatus(step, event.detail.success ? 'current' : 'error');
  }

  private get total() {
    return this.stepTargets.length;
  }

  private get currentStep(): HTMLElement | undefined {
    return this.stepTargets[this.currentValue - 1];
  }

  private get currentPanel(): HTMLElement | undefined {
    return this.panelTargets.find((panel) => Number(panel.dataset.step) === this.currentValue);
  }

  private fields(panel: HTMLElement) {
    return Array.from(panel.querySelectorAll<HTMLInputElement>('input, select, textarea')).filter(
      (field) => !field.disabled && field.willValidate,
    );
  }

  private validate() {
    const panel = this.currentPanel;
    const step = this.currentStep;
    if (!panel || !step) return true;
    const invalid = this.fields(panel).find((field) => !field.checkValidity());
    if (!invalid) return true;
    this.setStatus(step, 'error');
    invalid.reportValidity();
    invalid.focus();
    return false;
  }

  private go(step: number) {
    const back = step < this.currentValue;
    // Turns on the enter animations, which a page load shouldn't play.
    this.element.dataset.moved = '';
    this.element.dataset.direction = back ? 'back' : 'forward';
    this.currentValue = step;
    this.sync();
  }

  private setStatus(step: HTMLElement, status: Status) {
    step.dataset.status = status;
    if (status === 'current' || status === 'loading') step.setAttribute('aria-current', 'step');
    else step.removeAttribute('aria-current');
  }

  private sync() {
    const current = this.currentValue;
    const finished = current > this.total;

    this.stepTargets.forEach((step, index) => {
      const number = index + 1;
      this.setStatus(step, number < current ? 'complete' : number === current ? 'current' : 'upcoming');
    });
    this.panelTargets.forEach((panel) => (panel.hidden = Number(panel.dataset.step) !== current));
    this.completionTargets.forEach((el) => (el.hidden = !finished));
    this.syncButtons();

    const title = this.currentStep?.querySelector('[id$="-step-' + current + '"]')?.textContent ?? '';
    this.summaryTargets.forEach((el) => {
      if (finished) el.hidden = true;
      else {
        el.hidden = false;
        el.textContent = `${this.summaryValue.replace('%{current}', String(current)).replace('%{total}', String(this.total))}: ${title}`;
      }
    });

    const shown = finished ? this.completionTargets[0] : this.currentPanel;
    shown?.focus({ preventScroll: true });
    this.dispatch('change', { detail: { current, total: this.total } });
  }

  private syncButtons() {
    const current = this.currentValue;
    const finished = current > this.total;
    const last = current === this.total;
    this.previousTargets.forEach((button) => {
      button.hidden = finished || current <= 1;
    });
    this.nextTargets.forEach((el) => (el.hidden = finished || (last && this.submitTargets.length > 0)));
    this.submitTargets.forEach((el) => (el.hidden = !last));
  }
}
