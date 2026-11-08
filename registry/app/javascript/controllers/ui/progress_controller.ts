import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--progress"
//
// Moves the bar when its value changes. Set the value from anywhere, an
// upload's progress event for one:
//
//   bar.setAttribute('data-ui--progress-value-value', String(loaded / total * 100))
//
// Removing the attribute puts it back to "working on it", with no amount.
// The bar is drawn by the server first, so with no JavaScript it still shows
// where things stood; this only keeps it moving.
export default class extends Controller<HTMLElement> {
  static targets = ['bar', 'indicator', 'text'];
  static values = { value: Number, max: { type: Number, default: 100 }, format: { type: String, default: '%{percent}%' } };
  static classes = ['determinate', 'indeterminate'];

  declare readonly barTarget: HTMLElement;
  declare readonly indicatorTarget: HTMLElement;
  declare readonly textTarget: HTMLElement;
  declare readonly hasTextTarget: boolean;
  declare valueValue: number;
  declare readonly hasValueValue: boolean;
  declare readonly maxValue: number;
  declare readonly formatValue: string;
  declare readonly determinateClasses: string[];
  declare readonly indeterminateClasses: string[];

  private wasComplete = false;

  connect() {
    this.wasComplete = this.barTarget.dataset.state === 'complete';
  }

  valueValueChanged() {
    if (!this.hasBarTarget) return;
    this.hasValueValue ? this.showAmount() : this.showWorking();
  }

  maxValueChanged() {
    this.valueValueChanged();
  }

  private showAmount() {
    const max = this.maxValue > 0 ? this.maxValue : 100;
    const value = Math.min(Math.max(this.valueValue, 0), max);
    // Rounded down, so it never says 100% before it's done.
    const percent = Math.floor((value / max) * 100);
    const text = this.formatValue
      .replaceAll('%{value}', this.number(value))
      .replaceAll('%{max}', this.number(max))
      .replaceAll('%{percent}', String(percent));
    const complete = value >= max;

    this.indicatorTarget.classList.remove(...this.indeterminateClasses);
    this.indicatorTarget.classList.add(...this.determinateClasses);
    this.indicatorTarget.style.width = `${percent}%`;
    this.barTarget.dataset.state = complete ? 'complete' : 'loading';
    this.barTarget.setAttribute('aria-valuenow', this.number(value));
    this.barTarget.setAttribute('aria-valuemax', this.number(max));
    this.barTarget.setAttribute('aria-valuetext', text);
    this.barTarget.toggleAttribute('aria-busy', !complete);
    if (this.hasTextTarget) this.textTarget.textContent = text;

    if (complete && !this.wasComplete) this.dispatch('complete', { detail: { value, max } });
    this.wasComplete = complete;
  }

  private showWorking() {
    this.indicatorTarget.classList.remove(...this.determinateClasses);
    this.indicatorTarget.classList.add(...this.indeterminateClasses);
    this.indicatorTarget.style.removeProperty('width');
    this.barTarget.dataset.state = 'indeterminate';
    this.barTarget.removeAttribute('aria-valuenow');
    this.barTarget.removeAttribute('aria-valuetext');
    this.barTarget.setAttribute('aria-busy', 'true');
    if (this.hasTextTarget) this.textTarget.textContent = '';
    this.wasComplete = false;
  }

  // 3, not 3.0; 2.5 stays 2.5.
  private number(n: number) {
    return Number.isInteger(n) ? String(n) : String(Math.round(n * 100) / 100);
  }

  declare readonly hasBarTarget: boolean;
}
