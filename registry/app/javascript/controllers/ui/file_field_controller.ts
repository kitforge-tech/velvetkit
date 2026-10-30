import { Controller } from '@hotwired/stimulus';

/**
 * UI::FileField controller — drag-and-drop over a native <input type="file">.
 *
 * The <label> wrapping the input already opens the native picker on click,
 * no JS needed for that. This only adds what a label can't: highlighting the
 * dropzone while dragging, assigning dropped files to the input, and
 * listing the chosen file names.
 */
export default class extends Controller<HTMLElement> {
  static targets = ['dropzone', 'input', 'filenames'];

  declare readonly dropzoneTarget: HTMLElement;
  declare readonly inputTarget: HTMLInputElement;
  declare readonly hasFilenamesTarget: boolean;
  declare readonly filenamesTarget: HTMLElement;

  connect() {
    this.updateNames();
  }

  dragOver(event: DragEvent) {
    event.preventDefault();
    if (this.inputTarget.disabled) return;
    this.dropzoneTarget.dataset.drag = 'true';
  }

  dragLeave() {
    delete this.dropzoneTarget.dataset.drag;
  }

  drop(event: DragEvent) {
    event.preventDefault();
    delete this.dropzoneTarget.dataset.drag;

    const files = event.dataTransfer?.files;
    if (!files || !files.length || this.inputTarget.disabled) return;

    this.inputTarget.files = files;
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }));
  }

  updateNames() {
    if (!this.hasFilenamesTarget) return;
    const names = Array.from(this.inputTarget.files ?? []).map((file) => file.name);
    this.filenamesTarget.textContent = names.join(', ');
  }
}
