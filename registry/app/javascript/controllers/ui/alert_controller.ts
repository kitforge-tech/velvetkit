import { Controller } from '@hotwired/stimulus';

export default class extends Controller<HTMLElement> {
  dismiss() {
    this.element.remove();
  }
}
