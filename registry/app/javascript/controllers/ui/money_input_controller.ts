import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--money-input"
//
// Regroups the amount as it's typed and keeps the caret where it was among
// the digits, so typing in the middle of "1,23,456" doesn't throw it to the
// end. The hidden field gets the plain number, built from the digits as a
// string: no floats, so nothing is rounded on the way to the server.
const MAX_DIGITS = 15;

type Amount = { negative: boolean; whole: string; fraction: string; point: boolean };

export default class extends Controller<HTMLElement> {
  static targets = ['field', 'value'];
  static values = {
    separator: { type: String, default: '.' },
    delimiter: { type: String, default: ',' },
    precision: { type: Number, default: 2 },
    grouping: { type: String, default: 'thousands' },
    negative: Boolean,
    step: { type: String, default: '1' },
  };

  declare readonly fieldTarget: HTMLInputElement;
  declare readonly valueTarget: HTMLInputElement;
  declare readonly separatorValue: string;
  declare readonly delimiterValue: string;
  declare readonly precisionValue: number;
  declare readonly groupingValue: string;
  declare readonly negativeValue: boolean;
  declare readonly stepValue: string;

  connect() {
    this.element.closest('form')?.addEventListener('reset', this.afterReset);
  }

  disconnect() {
    this.element.closest('form')?.removeEventListener('reset', this.afterReset);
  }

  type() {
    const field = this.fieldTarget;
    const caret = field.selectionStart ?? field.value.length;
    const { amount, kept } = this.read(field.value, caret);
    const text = this.write(amount);

    field.value = text;
    const at = this.caretAt(text, kept);
    if (document.activeElement === field) field.setSelectionRange(at, at);
    this.valueTarget.value = this.plain(amount);
  }

  // Before a keystroke lands. Backspace just after a delimiter, or Delete
  // just before one, would remove only the comma, which regrouping puts
  // straight back: step over it so the digit beside it goes instead.
  guard(event: InputEvent) {
    const field = this.fieldTarget;
    // No decimals: a typed point is refused, or the digits after it would
    // join the whole amount once it's dropped.
    if (event.inputType === 'insertText' && this.precisionValue === 0 && event.data && this.isPoint(event.data)) {
      event.preventDefault();
      return;
    }

    const { selectionStart: start, selectionEnd: end } = field;
    if (start === null || start !== end) return;

    if (event.inputType === 'deleteContentBackward' && field.value[start - 1] === this.delimiterValue) {
      field.setSelectionRange(start - 1, start - 1);
    } else if (event.inputType === 'deleteContentForward' && field.value[start] === this.delimiterValue) {
      field.setSelectionRange(start + 1, start + 1);
    }
  }

  // ↑ and ↓ add or take away a step (one whole unit unless `step:` says),
  // Shift ten. Counted in paise or cents as whole numbers, so nothing drifts.
  nudge(event: KeyboardEvent) {
    if ((event.key !== 'ArrowUp' && event.key !== 'ArrowDown') || event.altKey || event.metaKey || event.ctrlKey) return;
    if (this.fieldTarget.readOnly) return;

    event.preventDefault();
    const { amount } = this.read(this.fieldTarget.value, 0);
    const scale = 10n ** BigInt(this.precisionValue);
    let minor = this.minor(amount, scale);
    const step = this.minor(this.read(this.stepValue.replace('.', this.separatorValue), 0).amount, scale) || scale;
    minor += (event.key === 'ArrowUp' ? 1n : -1n) * step * (event.shiftKey ? 10n : 1n);
    if (minor < 0n && !this.negativeValue) minor = 0n;

    const digits = (minor < 0n ? -minor : minor).toString().padStart(this.precisionValue + 1, '0');
    const cut = digits.length - this.precisionValue;
    const next: Amount = {
      negative: minor < 0n,
      whole: digits.slice(0, cut),
      fraction: digits.slice(cut),
      point: this.precisionValue > 0,
    };
    const text = this.write(next);
    if (text === this.fieldTarget.value) return;

    this.fieldTarget.value = text;
    this.fieldTarget.setSelectionRange(text.length, text.length);
    this.valueTarget.value = this.plain(next);
    this.fieldTarget.dispatchEvent(new Event('input', { bubbles: true }));
    this.fieldTarget.dispatchEvent(new Event('change', { bubbles: true }));
  }

  // Leaving the field fills in the decimals: "1,200" becomes "1,200.00".
  finish() {
    const { amount } = this.read(this.fieldTarget.value, 0);
    if (!amount.whole && !amount.fraction) {
      this.fieldTarget.value = '';
      this.valueTarget.value = '';
      return;
    }

    const full = { ...amount, whole: amount.whole || '0', point: this.precisionValue > 0 };
    full.fraction = full.fraction.padEnd(this.precisionValue, '0');
    this.fieldTarget.value = this.write(full);
    this.valueTarget.value = this.plain(full);
  }

  // What was typed or pasted, as an amount, and how many of its characters
  // (digits, the point, a minus) came before the caret.
  private read(text: string, caret: number): { amount: Amount; kept: number } {
    const amount: Amount = { negative: false, whole: '', fraction: '', point: false };
    let kept = 0;
    let zeros = 0;
    let zeroBefore = false;
    // A point typed where there are no decimals ends the amount: "15800.5" is 15800.
    let ended = false;

    [...text].forEach((char, index) => {
      const before = index < caret;
      if (ended) return;
      if (char === '-' && this.negativeValue && !amount.negative && !amount.whole && !amount.point) {
        amount.negative = true;
      } else if (this.isPoint(char) && !amount.point && this.precisionValue === 0) {
        ended = true;
        return;
      } else if (this.isPoint(char) && !amount.point) {
        amount.point = true;
        // ".5" reads as "0.5"; the 0 is one more character before the caret.
        if (!amount.whole) {
          amount.whole = '0';
          if (before) kept += 1;
        }
      } else if (/\d/.test(char)) {
        if (amount.point) {
          if (amount.fraction.length >= this.precisionValue) return;
          amount.fraction += char;
        } else {
          if (amount.whole.length >= MAX_DIGITS) return;
          // Leading zeros go, unless the 0 is all there is.
          if (amount.whole === '0') {
            amount.whole = char;
            if (zeroBefore) zeros += 1;
          } else {
            amount.whole += char;
          }
          if (amount.whole === '0') zeroBefore = before;
        }
      } else {
        return;
      }
      if (before) kept += 1;
    });

    return { amount, kept: kept - zeros };
  }

  // An amount in paise or cents, as a whole number.
  private minor(amount: Amount, scale: bigint): bigint {
    const whole = BigInt(amount.whole || '0') * scale;
    const fraction = BigInt(amount.fraction.padEnd(this.precisionValue, '0') || '0');
    const total = whole + fraction;
    return amount.negative ? -total : total;
  }

  private write(amount: Amount): string {
    const whole = this.group(amount.whole);
    const point = amount.point ? this.separatorValue + amount.fraction : '';
    return `${amount.negative ? '-' : ''}${whole}${point}`;
  }

  private plain(amount: Amount): string {
    if (!amount.whole && !amount.fraction) return '';

    const fraction = amount.fraction ? `.${amount.fraction}` : '';
    return `${amount.negative ? '-' : ''}${amount.whole || '0'}${fraction}`;
  }

  // 1234567 as 1,234,567, or the Indian way, 12,34,567.
  private group(digits: string): string {
    const d = this.delimiterValue;
    if (this.groupingValue !== 'indian') return digits.replace(/\B(?=(\d{3})+(?!\d))/g, d);
    if (digits.length <= 3) return digits;

    return `${digits.slice(0, -3).replace(/\B(?=(\d{2})+(?!\d))/g, d)}${d}${digits.slice(-3)}`;
  }

  // The place in the new text after `kept` characters that aren't delimiters.
  private caretAt(text: string, kept: number): number {
    if (kept <= 0) return 0;

    let seen = 0;
    for (let index = 0; index < text.length; index += 1) {
      if (text[index] !== this.delimiterValue || index === this.pointIndex(text)) seen += 1;
      if (seen === kept) return index + 1;
    }
    return text.length;
  }

  private pointIndex(text: string): number {
    return this.separatorValue === this.delimiterValue ? -1 : text.indexOf(this.separatorValue);
  }

  // The locale's decimal mark, or a full stop where that isn't the delimiter:
  // the key on a phone's decimal pad.
  private isPoint(char: string): boolean {
    return char === this.separatorValue || (char === '.' && this.delimiterValue !== '.');
  }

  private afterReset = () =>
    requestAnimationFrame(() => {
      this.type();
      this.finish();
    });
}
