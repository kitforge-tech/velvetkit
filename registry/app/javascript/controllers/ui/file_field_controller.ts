import { Controller } from '@hotwired/stimulus';
import { DirectUpload } from '@rails/activestorage';

// Connects to data-controller="ui--file-field"
//
// The <label> around the input already opens the system picker, with no
// JavaScript. This adds what a label can't: dropping files on it, a tile for
// each chosen file with a thumbnail and a way to take it out again, checking
// type and size as files arrive, and, with direct upload, sending each file to
// storage straight away with a progress bar.
//
// Without direct upload the input itself carries the files, so it's rebuilt
// to match the tiles whenever one is added or taken out. With it, the input
// is emptied as each file starts uploading and a hidden field takes the
// file's signed id instead, so the form submits ids, not bytes.
type Labels = {
  remove: string; uploading: string; uploaded: string; failed: string; retry: string;
  too_big: string; max: string | null; wrong_type: string; waiting: string; added: string; removed: string;
  units: { byte: string; kb: string; mb: string; gb: string };
};
type Upload = { xhr?: XMLHttpRequest; done: boolean };

export default class extends Controller<HTMLElement> {
  static targets = ['dropzone', 'input', 'filenames', 'list', 'template', 'item', 'notice', 'status'];
  static values = {
    preview: Boolean,
    directUpload: Boolean,
    url: String,
    name: String,
    multiple: Boolean,
    accept: String,
    maxSize: Number,
    required: Boolean,
    labels: Object,
  };

  declare readonly dropzoneTarget: HTMLElement;
  declare readonly inputTarget: HTMLInputElement;
  declare readonly hasFilenamesTarget: boolean;
  declare readonly filenamesTarget: HTMLElement;
  declare readonly listTarget: HTMLElement;
  declare readonly templateTarget: HTMLTemplateElement;
  declare readonly itemTargets: HTMLElement[];
  declare readonly hasNoticeTarget: boolean;
  declare readonly noticeTarget: HTMLElement;
  declare readonly hasStatusTarget: boolean;
  declare readonly statusTarget: HTMLElement;
  declare readonly previewValue: boolean;
  declare readonly directUploadValue: boolean;
  declare readonly urlValue: string;
  declare readonly nameValue: string;
  declare readonly multipleValue: boolean;
  declare readonly acceptValue: string;
  declare readonly maxSizeValue: number;
  declare readonly requiredValue: boolean;
  declare readonly labelsValue: Labels;

  // What each tile stands for, beyond its markup.
  private files = new WeakMap<HTMLElement, File>();
  private uploads = new WeakMap<HTMLElement, Upload>();
  private objectUrls = new WeakMap<HTMLElement, string>();
  private waitingToSubmit = false;
  private onSubmit = (event: SubmitEvent) => this.holdForUploads(event);

  connect() {
    // With direct upload the files travel separately, so the input itself
    // sends nothing, not even an empty file.
    if (this.directUploadValue) this.inputTarget.removeAttribute('name');
    this.inputTarget.form?.addEventListener('submit', this.onSubmit);
    if (!this.previewValue) this.updateNames();
  }

  disconnect() {
    this.inputTarget.form?.removeEventListener('submit', this.onSubmit);
    this.itemTargets.forEach((item) => this.forget(item));
  }

  // ── Arriving files ──────────────────────────────────────────────────────

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

    const files = Array.from(event.dataTransfer?.files ?? []);
    if (!files.length || this.inputTarget.disabled) return;

    if (this.previewValue) {
      this.add(this.multipleValue ? files : files.slice(0, 1));
    } else {
      this.inputTarget.files = event.dataTransfer!.files;
      this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }));
    }
  }

  // The picker's choice. Without previews, only the names are listed.
  chosen() {
    if (!this.previewValue) return this.updateNames();

    const files = Array.from(this.inputTarget.files ?? []);
    // The input's own list is replaced as the tiles are made, so the files
    // already chosen aren't counted twice.
    const fresh = files.filter((file) => !this.itemTargets.some((item) => this.files.get(item) === file));
    if (fresh.length) this.add(fresh);
  }

  updateNames() {
    if (!this.hasFilenamesTarget) return;
    this.filenamesTarget.textContent = Array.from(this.inputTarget.files ?? []).map((file) => file.name).join(', ');
  }

  private add(files: File[]) {
    // A single file replaces whatever was there, kept files included.
    if (!this.multipleValue) this.itemTargets.forEach((item) => this.discard(item));

    files.forEach((file) => {
      const item = this.makeTile(file);
      const problem = this.problemWith(file);
      if (problem) {
        this.setState(item, 'error', problem);
        return;
      }
      this.files.set(item, file);
      if (this.directUploadValue) this.upload(item, file);
    });
    this.syncInput();
    this.say(this.labelsValue.added.replace('%{name}', files.map((f) => f.name).join(', ')));
  }

  private makeTile(file: File): HTMLElement {
    const item = this.templateTarget.content.firstElementChild!.cloneNode(true) as HTMLElement;
    this.part(item, 'name').textContent = file.name;
    this.part(item, 'name').title = file.name;
    this.part(item, 'meta').textContent = this.size(file.size);
    this.part(item, 'remove').setAttribute('aria-label', this.labelsValue.remove.replace('%{name}', file.name));
    this.part(item, 'progress').setAttribute('aria-label', file.name);

    if (file.type.startsWith('image/')) {
      const url = URL.createObjectURL(file);
      this.objectUrls.set(item, url);
      const thumb = this.part(item, 'thumb') as HTMLImageElement;
      thumb.src = url;
      thumb.hidden = false;
      this.part(item, 'icon').hidden = true;
    }
    this.listTarget.append(item);
    return item;
  }

  // The same rules as `accept` and `max_size`, for dropped files too, which
  // the picker's filter never sees.
  private problemWith(file: File): string | null {
    if (this.acceptValue && !this.accepts(file)) return this.labelsValue.wrong_type;
    if (this.maxSizeValue && file.size > this.maxSizeValue) {
      return this.labelsValue.too_big.replace('%{max}', this.labelsValue.max ?? this.size(this.maxSizeValue));
    }
    return null;
  }

  private accepts(file: File) {
    return this.acceptValue.split(',').map((rule) => rule.trim().toLowerCase()).filter(Boolean).some((rule) => {
      if (rule.startsWith('.')) return file.name.toLowerCase().endsWith(rule);
      if (rule.endsWith('/*')) return file.type.toLowerCase().startsWith(rule.slice(0, -1));
      return file.type.toLowerCase() === rule;
    });
  }

  // ── Taking files out ────────────────────────────────────────────────────

  remove(event: Event) {
    const item = (event.currentTarget as HTMLElement).closest<HTMLElement>('[data-ui--file-field-target="item"]');
    if (!item) return;

    const name = this.part(item, 'name').textContent ?? '';
    this.discard(item);
    this.syncInput();
    this.say(this.labelsValue.removed.replace('%{name}', name));
    this.inputTarget.focus();
  }

  private discard(item: HTMLElement) {
    this.forget(item);
    item.remove();
    this.settle();
  }

  private forget(item: HTMLElement) {
    this.uploads.get(item)?.xhr?.abort();
    const url = this.objectUrls.get(item);
    if (url) URL.revokeObjectURL(url);
  }

  // ── Uploading ───────────────────────────────────────────────────────────

  retry(event: Event) {
    const item = (event.currentTarget as HTMLElement).closest<HTMLElement>('[data-ui--file-field-target="item"]');
    const file = item && this.files.get(item);
    if (item && file) this.upload(item, file);
  }

  private upload(item: HTMLElement, file: File) {
    const state: Upload = { done: false };
    this.uploads.set(item, state);
    this.setState(item, 'uploading', this.labelsValue.uploading);
    this.setProgress(item, 0);

    const watch = (xhr: XMLHttpRequest) => {
      state.xhr = xhr;
      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable) this.setProgress(item, event.loaded / event.total);
      });
    };
    new DirectUpload(file, this.urlValue, {
      directUploadWillCreateBlobWithXHR: (xhr: XMLHttpRequest) => { state.xhr = xhr; },
      directUploadWillStoreFileWithXHR: watch,
    }).create((error: string | null, blob?: { signed_id: string }) => {
      state.done = true;
      if (!item.isConnected) return;
      if (error || !blob) {
        this.setState(item, 'error', this.labelsValue.failed);
        this.part(item, 'retry').hidden = false;
      } else {
        this.keep(item, blob.signed_id);
        this.setState(item, 'uploaded', `${this.size(file.size)} · ${this.labelsValue.uploaded}`);
      }
      this.settle();
    });
  }

  // The uploaded file's signed id goes in the form in its place.
  private keep(item: HTMLElement, signedId: string) {
    const field = document.createElement('input');
    field.type = 'hidden';
    field.name = this.nameValue;
    field.value = signedId;
    field.dataset.role = 'signed';
    item.append(field);
  }

  private setState(item: HTMLElement, state: string, meta: string) {
    item.dataset.state = state;
    this.part(item, 'meta').textContent = meta;
    this.part(item, 'retry').hidden = true;
    this.part(item, 'progress').hidden = state !== 'uploading';
  }

  private setProgress(item: HTMLElement, fraction: number) {
    const percent = Math.round(fraction * 100);
    this.part(item, 'bar').style.width = `${percent}%`;
    this.part(item, 'progress').setAttribute('aria-valuenow', String(percent));
  }

  private get uploading() {
    return this.itemTargets.some((item) => item.dataset.state === 'uploading');
  }

  // Sending the form mid-upload waits for the uploads, then sends it.
  private holdForUploads(event: SubmitEvent) {
    if (!this.uploading) return;

    event.preventDefault();
    event.stopImmediatePropagation();
    this.waitingToSubmit = true;
    if (this.hasNoticeTarget) this.noticeTarget.textContent = this.labelsValue.waiting;
  }

  private settle() {
    if (this.uploading) return;

    if (this.hasNoticeTarget) this.noticeTarget.textContent = '';
    if (this.waitingToSubmit) {
      this.waitingToSubmit = false;
      this.inputTarget.form?.requestSubmit();
    }
  }

  // ── The input itself ────────────────────────────────────────────────────

  // Without direct upload the input carries the files the tiles show; with
  // it, the input is emptied, since the files travel separately. Either way a
  // required field counts a kept or uploaded file as filled.
  private syncInput() {
    const carried = this.directUploadValue ? [] : this.itemTargets.map((item) => this.files.get(item)).filter((f): f is File => !!f);
    const list = new DataTransfer();
    carried.forEach((file) => list.items.add(file));
    this.inputTarget.files = list.files;

    const filled = this.itemTargets.some((item) => item.dataset.state !== 'error');
    if (this.requiredValue) this.inputTarget.required = !filled;
  }

  private say(text: string) {
    if (this.hasStatusTarget) this.statusTarget.textContent = text;
  }

  private part(item: HTMLElement, role: string): HTMLElement {
    return item.querySelector<HTMLElement>(`[data-role="${role}"]`)!;
  }

  // Written the way Rails writes it for the kept files beside it ("1.2 MB"),
  // in the units the locale gives.
  private size(bytes: number): string {
    const { units } = this.labelsValue;
    const steps: [number, string][] = [[1024 ** 3, units.gb], [1024 ** 2, units.mb], [1024, units.kb]];
    const [divisor, unit] = steps.find(([limit]) => bytes >= limit) ?? [1, units.byte];
    const value = bytes / divisor;
    const number = new Intl.NumberFormat(document.documentElement.lang || undefined, {
      maximumFractionDigits: value >= 100 || divisor === 1 ? 0 : value >= 10 ? 1 : 2,
    }).format(value);
    return `${number} ${unit}`;
  }
}
