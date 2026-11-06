import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--gallery"
//
// Swiping the main view is plain CSS scroll-snap; this keeps the thumbnails in
// step with it. The overlay is a native <dialog>, so the browser owns the focus
// trap, Escape and the dimmed page behind it.
//
// Zooming sizes the image inside a scrolling box instead of scaling it with a
// transform. That way panning is just scrolling, and touch, trackpad and wheel
// all work without any code here. Only dragging with a mouse needs help.
const ZOOM_STEPS = [1, 1.5, 2, 3, 4];
const MIN_ZOOM = ZOOM_STEPS[0];
const MAX_ZOOM = ZOOM_STEPS[ZOOM_STEPS.length - 1];
const CLICK_ZOOM = 2;
const DRAG_THRESHOLD = 4;
const PANE_GAP = 16;
// Room round the image at 100%, to keep it clear of the buttons.
const IMAGE_MARGIN_TOP = 64;
const IMAGE_MARGIN_SIDE = 72;
const IMAGE_MARGIN_SIDE_NARROW = 16;
const NARROW = 640;
const EASE_OUT = 'cubic-bezier(0.2, 0.8, 0.2, 1)';
const OPEN_MS = 280;
const CLOSE_MS = 220;
const SLIDE_MS = 240;
const SLIDE_DISTANCE = 48;
const ZOOM_MS = 220;
const FADE_MS = 160;

type Rect = { left: number; top: number; width: number; height: number };

type IndexEvent<E extends Event = Event> = E & { params: { index: number } };

export default class extends Controller<HTMLElement> {
  static targets = ['track', 'slide', 'thumbnail', 'status', 'dialog', 'viewport', 'zoomImage', 'zoomStatus', 'zoomIn', 'zoomOut', 'lens', 'pane'];
  static values = { position: String, zoomScale: Number };

  declare readonly trackTarget: HTMLElement;
  declare readonly slideTargets: HTMLElement[];
  declare readonly thumbnailTargets: HTMLElement[];
  declare readonly statusTarget: HTMLElement;
  declare readonly dialogTarget: HTMLDialogElement;
  declare readonly viewportTarget: HTMLElement;
  declare readonly zoomImageTarget: HTMLImageElement;
  declare readonly zoomStatusTarget: HTMLElement;
  declare readonly zoomInTarget: HTMLButtonElement;
  declare readonly zoomOutTarget: HTMLButtonElement;
  declare readonly hasPaneTarget: boolean;
  declare readonly lensTarget: HTMLElement;
  declare readonly paneTarget: HTMLElement;
  declare readonly positionValue: string;
  declare readonly zoomScaleValue: number;

  private index = 0;
  private heading: number | null = null;
  private frame?: number;
  private scale = MIN_ZOOM;
  private pan: { id: number; x: number; y: number; left: number; top: number } | null = null;
  private dragged = false;
  private closing: Animation[] | null = null;

  disconnect() {
    if (this.frame) cancelAnimationFrame(this.frame);
    this.cancelClosing();
    if (this.dialogTarget.open) this.dialogTarget.close();
  }

  // ── The main view ────────────────────────────────────────────────────────

  select(event: IndexEvent) {
    this.goTo(event.params.index);
  }

  previous() {
    this.move(-1);
  }

  next() {
    this.move(1);
  }

  private move(by: number) {
    const count = this.slideTargets.length;
    const index = (this.index + by + count) % count;
    if (this.dialogTarget.open) this.show(index, by);
    else this.goTo(index);
  }

  private goTo(index: number, behavior: ScrollBehavior = this.scrollBehavior) {
    this.heading = index;
    this.setIndex(index);
    this.trackTarget.scrollTo({ left: this.scrollPosition(this.trackTarget, this.slideTargets[index]), behavior });
  }

  // Follows a swipe. While heading for a chosen image, the ones passed on the
  // way aren't announced or highlighted.
  scrolled() {
    if (this.frame) return;

    this.frame = requestAnimationFrame(() => {
      this.frame = undefined;
      const nearest = this.nearestSlide();
      if (this.heading === null) this.setIndex(nearest);
      else if (nearest === this.heading) this.heading = null;
    });
  }

  // A finger or mouse on the strip takes over from wherever it was heading.
  released() {
    this.heading = null;
  }

  private nearestSlide(): number {
    const track = this.trackTarget.getBoundingClientRect();
    const middle = track.left + track.width / 2;
    let nearest = 0;
    let closest = Infinity;
    this.slideTargets.forEach((slide, index) => {
      const rect = slide.getBoundingClientRect();
      const distance = Math.abs(rect.left + rect.width / 2 - middle);
      if (distance < closest) {
        closest = distance;
        nearest = index;
      }
    });
    return nearest;
  }

  private setIndex(index: number) {
    if (index === this.index && this.statusTarget.dataset.ready) return;

    this.index = index;
    this.statusTarget.dataset.ready = 'true';
    this.statusTarget.textContent = this.position(index);
    this.slideTargets.forEach((_, i) => this.slideButton(i)?.setAttribute('tabindex', i === index ? '0' : '-1'));
    this.thumbnailTargets.forEach((thumbnail, i) => {
      if (i === index) thumbnail.setAttribute('aria-current', 'true');
      else thumbnail.removeAttribute('aria-current');
    });
    const strip = this.thumbnailTargets[index]?.closest('ul');
    if (strip) strip.scrollTo({ left: this.scrollPosition(strip, this.thumbnailTargets[index]), behavior: this.scrollBehavior });
  }

  private slideButton(index: number) {
    return this.slideTargets[index].querySelector('button');
  }

  // Where to scroll `box` so `item` sits in its middle. Measured from what's on
  // screen, so it holds in a right-to-left page, where scrollLeft runs negative.
  private scrollPosition(box: HTMLElement, item: HTMLElement): number {
    const boxRect = box.getBoundingClientRect();
    const itemRect = item.getBoundingClientRect();
    return box.scrollLeft + itemRect.left - boxRect.left - (boxRect.width - itemRect.width) / 2;
  }

  private position(index: number): string {
    return this.positionValue.replace('%{current}', String(index + 1)).replace('%{total}', String(this.slideTargets.length));
  }

  private get scrollBehavior(): ScrollBehavior {
    return this.reducedMotion ? 'auto' : 'smooth';
  }

  // ── Hover zoom ───────────────────────────────────────────────────────────

  // A lens on the image, and what's under it magnified in a pane the same size
  // as the image. Sized from the picture as drawn, which can be smaller than its
  // frame (`fit: :contain`) or larger (`fit: :cover`).
  hover(event: IndexEvent<PointerEvent>) {
    if (event.pointerType !== 'mouse' || this.dialogTarget.open) return;

    const slide = this.slideTargets[event.params.index];
    const image = slide.querySelector('img');
    if (!image?.naturalWidth) return;

    const frame = slide.getBoundingClientRect();
    const scale = this.zoomScaleValue;
    const drawn = this.drawnImage(slide, image);
    const left = drawn.left - frame.left;
    const top = drawn.top - frame.top;
    const { width, height } = drawn;
    const lensWidth = frame.width / scale;
    const lensHeight = frame.height / scale;
    const lensLeft = this.clampLens(event.clientX - frame.left - lensWidth / 2, left, width, frame.width, lensWidth);
    const lensTop = this.clampLens(event.clientY - frame.top - lensHeight / 2, top, height, frame.height, lensHeight);

    const inside = !this.hasRoomBeside(frame);
    const lens = this.lensTarget;
    lens.toggleAttribute('data-shown', !inside);
    lens.style.width = `${lensWidth}px`;
    lens.style.height = `${lensHeight}px`;
    lens.style.transform = `translate(${lensLeft}px, ${lensTop}px)`;

    const pane = this.paneTarget;
    const large = slide.dataset.zoomSrc ?? '';
    if (pane.dataset.src !== large) {
      pane.dataset.src = large;
      // The picture already on screen shows through until the large one arrives.
      pane.style.backgroundImage = [large, image.currentSrc].map((src) => `url("${src.replace(/"/g, '%22')}")`).join(', ');
    }
    pane.toggleAttribute('data-inside', inside);
    pane.toggleAttribute('data-shown', true);
    pane.style.width = `${frame.width}px`;
    pane.style.height = `${frame.height}px`;
    pane.style.backgroundSize = `${width * scale}px ${height * scale}px`;
    pane.style.backgroundPosition = `${(left - lensLeft) * scale}px ${(top - lensTop) * scale}px`;
  }

  hoverEnd() {
    if (!this.hasPaneTarget) return;

    this.paneTarget.removeAttribute('data-shown');
    this.lensTarget.removeAttribute('data-shown');
  }

  // Where the picture is really drawn in its slide, which can be smaller than the
  // slide (`fit: :contain`) or larger (`fit: :cover`).
  private drawnImage(slide: HTMLElement, image: HTMLImageElement): Rect {
    const frame = slide.getBoundingClientRect();
    const cover = getComputedStyle(image).objectFit === 'cover';
    const fit = (cover ? Math.max : Math.min)(frame.width / image.naturalWidth, frame.height / image.naturalHeight);
    const width = image.naturalWidth * fit;
    const height = image.naturalHeight * fit;
    return { left: frame.left + (frame.width - width) / 2, top: frame.top + (frame.height - height) / 2, width, height };
  }

  // Keeps the lens on the picture, or centres it where the picture is too short
  // to hold it.
  private clampLens(wanted: number, start: number, size: number, frame: number, lens: number): number {
    const min = Math.max(0, start);
    const max = Math.min(frame, start + size) - lens;
    return max < min ? (min + max) / 2 : Math.min(max, Math.max(min, wanted));
  }

  private hasRoomBeside(frame: DOMRect): boolean {
    const rtl = getComputedStyle(this.element).direction === 'rtl';
    if (rtl) return frame.left - PANE_GAP - frame.width >= 0;
    return frame.right + PANE_GAP + frame.width <= document.documentElement.clientWidth;
  }

  // ── The overlay ──────────────────────────────────────────────────────────

  // Focus goes to the dialog, so it opens without a ring on any one button. The
  // image grows out of its place on the page.
  open(event: IndexEvent) {
    this.hoverEnd();
    this.cancelClosing();
    this.dialogTarget.showModal();
    this.dialogTarget.focus();
    this.show(event.params.index);

    const fade = { duration: OPEN_MS, easing: 'ease-out' };
    this.animate(this.dialogTarget, { opacity: [0, 1] }, { ...fade, pseudoElement: '::backdrop' });
    this.overlayButtons.forEach((button) => this.animate(button, { opacity: [0, 1] }, fade));

    const slide = this.slideTargets[this.index];
    const image = this.zoomImageTarget;
    const origin = slide.querySelector('img');
    if (origin?.naturalWidth && image.naturalWidth) {
      this.fly(this.drawnImage(slide, origin), image.getBoundingClientRect(), OPEN_MS);
    } else {
      this.animate(image, { opacity: [0, 1] }, fade);
    }
  }

  // The image goes back to its place on the page as the backdrop fades, and the
  // dialog only really closes after that. Going back to the image last looked at
  // comes first, so that's the place it flies to.
  close() {
    if (this.closing) return;

    this.goTo(this.index, 'auto');
    const slide = this.slideTargets[this.index];
    const image = this.zoomImageTarget;
    const origin = slide.querySelector('img');
    const fade = { duration: CLOSE_MS, easing: 'ease-in', fill: 'forwards' as const };
    const animations = [
      this.animate(this.dialogTarget, { opacity: [1, 0] }, { ...fade, pseudoElement: '::backdrop' }),
      ...this.overlayButtons.map((button) => this.animate(button, { opacity: [1, 0] }, fade)),
      origin?.naturalWidth && image.naturalWidth
        ? this.fly(image.getBoundingClientRect(), this.drawnImage(slide, origin), CLOSE_MS, true)
        : this.animate(image, { opacity: [1, 0] }, fade),
    ].filter((animation): animation is Animation => animation !== null);

    if (animations.length === 0) {
      this.dialogTarget.close();
      return;
    }
    this.closing = animations;
    Promise.all(animations.map((animation) => animation.finished))
      .then(() => {
        if (this.closing === animations) this.dialogTarget.close();
      })
      .catch(() => {});
  }

  // Escape runs through the same closing animation.
  cancel(event: Event) {
    event.preventDefault();
    this.close();
  }

  // However the dialog closed, focus lands on the image last looked at, not the
  // one the dialog was opened from.
  closed() {
    this.cancelClosing();
    this.goTo(this.index, 'auto');
    this.slideButton(this.index)?.focus({ preventScroll: true });
    this.zoomImageTarget.removeAttribute('style');
    this.setScale(MIN_ZOOM);
  }

  private cancelClosing() {
    const animations = this.closing;
    this.closing = null;
    animations?.forEach((animation) => animation.cancel());
  }

  // What's on the page shows at once, since it's already loaded, and the large
  // image replaces it when it arrives. It's only asked for here, so it costs
  // nothing until opened. `direction` slides the old image out and the new one in.
  private show(index: number, direction = 0) {
    const slide = this.slideTargets[index];
    const image = this.zoomImageTarget;
    const large = slide.dataset.zoomSrc ?? '';
    const shown = slide.querySelector('img');
    const ready = shown?.complete && shown.naturalWidth > 0 ? shown.currentSrc : '';

    if (direction) this.slideOut(direction);
    this.setIndex(index);
    this.zoomStatusTarget.textContent = this.position(index);
    this.scale = MIN_ZOOM;
    image.src = ready || large;
    image.alt = slide.dataset.alt ?? '';
    this.layout();
    this.viewportTarget.scrollTo(0, 0);
    this.loadLarge(index, large);
    if (direction) {
      this.animate(image, { opacity: [0, 1], transform: [`translateX(${direction * SLIDE_DISTANCE}px)`, 'none'] }, { duration: SLIDE_MS, easing: EASE_OUT });
    }
  }

  private loadLarge(index: number, large: string) {
    const image = this.zoomImageTarget;
    if (!large || image.src === new URL(large, window.location.href).href) return;

    const loader = new Image();
    loader.onload = () => {
      if (this.index !== index || !this.dialogTarget.open) return;

      this.morph(ZOOM_MS, () => {
        image.src = loader.src;
        this.layout();
      });
    };
    loader.src = large;
  }

  // A copy of the outgoing image, left to slide away while the real one changes.
  private slideOut(direction: number) {
    const image = this.zoomImageTarget;
    if (!image.naturalWidth || this.reducedMotion) return;

    const rect = image.getBoundingClientRect();
    const ghost = image.cloneNode() as HTMLImageElement;
    ghost.removeAttribute('data-ui--gallery-target');
    ghost.removeAttribute('data-action');
    ghost.alt = '';
    ghost.setAttribute('aria-hidden', 'true');
    Object.assign(ghost.style, {
      position: 'fixed', left: `${rect.left}px`, top: `${rect.top}px`, width: `${rect.width}px`, height: `${rect.height}px`,
      margin: '0', pointerEvents: 'none',
    });
    this.dialogTarget.append(ghost);
    const animation = this.animate(ghost, { opacity: [1, 0], transform: ['none', `translateX(${-direction * SLIDE_DISTANCE}px)`] }, { duration: SLIDE_MS, easing: EASE_OUT });
    if (animation) animation.onfinish = animation.oncancel = () => ghost.remove();
    else ghost.remove();
  }

  // Moves the image from one place and size on screen to another, by transform,
  // so nothing is laid out again on the way.
  private fly(from: Rect, to: Rect, duration: number, hold = false): Animation | null {
    const image = this.zoomImageTarget;
    const place = image.getBoundingClientRect();
    const transform = (rect: Rect) =>
      `translate(${rect.left - place.left}px, ${rect.top - place.top}px) scale(${rect.width / place.width}, ${rect.height / place.height})`;
    image.style.transformOrigin = '0 0';
    return this.animate(image, { transform: [transform(from), transform(to)] }, { duration, easing: EASE_OUT, fill: hold ? 'forwards' : 'none' });
  }

  // Runs a change that moves or resizes the image, and eases it across.
  private morph(duration: number, change: () => void) {
    const image = this.zoomImageTarget;
    const before = image.getBoundingClientRect();
    change();
    const after = image.getBoundingClientRect();
    if (before.width > 0 && after.width > 0) this.fly(before, after, duration);
  }

  private animate(element: Element, keyframes: PropertyIndexedKeyframes, options: KeyframeAnimationOptions): Animation | null {
    return this.reducedMotion ? null : element.animate(keyframes, options);
  }

  private get reducedMotion(): boolean {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  private get overlayButtons(): HTMLElement[] {
    return Array.from(this.dialogTarget.querySelectorAll('button'));
  }

  // Sizes the image to fit the window, times the zoom. It's never stretched past
  // its own size at 100%, so a small image isn't blurred until someone asks.
  layout() {
    if (!this.dialogTarget.open) return;

    const image = this.zoomImageTarget;
    const viewport = this.viewportTarget;
    if (image.naturalWidth > 0) {
      const side = viewport.clientWidth < NARROW ? IMAGE_MARGIN_SIDE_NARROW : IMAGE_MARGIN_SIDE;
      const room = { width: viewport.clientWidth - side * 2, height: viewport.clientHeight - IMAGE_MARGIN_TOP * 2 };
      const fit = Math.min(room.width / image.naturalWidth, room.height / image.naturalHeight, 1);
      image.style.width = `${image.naturalWidth * fit * this.scale}px`;
      image.style.height = `${image.naturalHeight * fit * this.scale}px`;
    }
    this.setScale(this.scale);
  }

  private setScale(scale: number) {
    this.scale = scale;
    this.viewportTarget.toggleAttribute('data-zoomed', scale > MIN_ZOOM);
    const atMin = scale <= MIN_ZOOM;
    const atMax = scale >= MAX_ZOOM;
    if (!atMin) this.zoomOutTarget.disabled = false;
    if (!atMax) this.zoomInTarget.disabled = false;
    if (atMin) this.turnOff(this.zoomOutTarget, this.zoomInTarget);
    if (atMax) this.turnOff(this.zoomInTarget, this.zoomOutTarget);
  }

  // A button that turns off under the keyboard would drop focus out of the dialog.
  private turnOff(button: HTMLButtonElement, other: HTMLButtonElement) {
    if (document.activeElement === button) other.focus();
    button.disabled = true;
  }

  zoomIn() {
    const step = ZOOM_STEPS.find((zoom) => zoom > this.scale);
    if (step) this.zoomTo(step);
  }

  zoomOut() {
    const step = [...ZOOM_STEPS].reverse().find((zoom) => zoom < this.scale);
    if (step) this.zoomTo(step);
  }

  // Keeps the spot at (x, y) where it is on screen, by default the middle. A
  // trackpad pinch is already gradual, so `eased` is off for it.
  private zoomTo(scale: number, x?: number, y?: number, eased = true) {
    const viewport = this.viewportTarget.getBoundingClientRect();
    const pointX = x ?? viewport.left + viewport.width / 2;
    const pointY = y ?? viewport.top + viewport.height / 2;
    const before = this.zoomImageTarget.getBoundingClientRect();
    if (before.width === 0 || before.height === 0) return;

    const change = () => {
      const spotX = (pointX - before.left) / before.width;
      const spotY = (pointY - before.top) / before.height;
      this.scale = scale;
      this.layout();
      const after = this.zoomImageTarget.getBoundingClientRect();
      this.viewportTarget.scrollBy(after.left + spotX * after.width - pointX, after.top + spotY * after.height - pointY);
    };
    if (eased) this.morph(ZOOM_MS, change);
    else change();
  }

  viewportClick(event: MouseEvent) {
    if (this.dragged) {
      this.dragged = false;
      return;
    }
    if (event.target === this.zoomImageTarget) {
      if (this.scale > MIN_ZOOM) this.zoomTo(MIN_ZOOM);
      else this.zoomTo(CLICK_ZOOM, event.clientX, event.clientY);
    } else {
      this.close();
    }
  }

  // A trackpad pinch arrives as a wheel event with the control key held.
  wheel(event: WheelEvent) {
    if (!event.ctrlKey) return;

    event.preventDefault();
    const scale = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, this.scale * Math.exp(-event.deltaY * 0.01)));
    this.zoomTo(scale, event.clientX, event.clientY, false);
  }

  panStart(event: PointerEvent) {
    this.dragged = false;
    if (event.pointerType !== 'mouse' || event.button !== 0) return;
    if (this.scale === MIN_ZOOM || event.target !== this.zoomImageTarget) return;

    const { scrollLeft: left, scrollTop: top } = this.viewportTarget;
    this.pan = { id: event.pointerId, x: event.clientX, y: event.clientY, left, top };
  }

  // Only captures the pointer once it's really a drag, so that a plain click
  // still lands on the image.
  panMove(event: PointerEvent) {
    if (!this.pan || event.pointerId !== this.pan.id) return;

    const x = event.clientX - this.pan.x;
    const y = event.clientY - this.pan.y;
    if (!this.dragged && Math.hypot(x, y) < DRAG_THRESHOLD) return;

    if (!this.dragged) this.viewportTarget.setPointerCapture(event.pointerId);
    this.dragged = true;
    this.viewportTarget.scrollTo(this.pan.left - x, this.pan.top - y);
  }

  panEnd() {
    this.pan = null;
  }

  // ── Keys ─────────────────────────────────────────────────────────────────

  keydown(event: KeyboardEvent) {
    if (event.ctrlKey || event.metaKey || event.altKey) return;

    if (this.dialogTarget.open) this.dialogKeydown(event);
    else if (this.element.contains(event.target as Node)) this.galleryKeydown(event);
  }

  private galleryKeydown(event: KeyboardEvent) {
    const by = this.arrowDirection(event);
    if (!by) return;

    event.preventDefault();
    this.move(by);
  }

  // Zoomed in, the arrow keys are left to scroll the image.
  private dialogKeydown(event: KeyboardEvent) {
    const by = this.arrowDirection(event);
    if (by && this.scale === MIN_ZOOM) {
      event.preventDefault();
      this.move(by);
    } else if (event.key === '+' || event.key === '=') {
      event.preventDefault();
      this.zoomIn();
    } else if (event.key === '-') {
      event.preventDefault();
      this.zoomOut();
    } else if (event.key === '0') {
      event.preventDefault();
      this.zoomTo(MIN_ZOOM);
    }
  }

  private arrowDirection(event: KeyboardEvent): number {
    const forward = getComputedStyle(this.element).direction === 'rtl' ? -1 : 1;
    if (event.key === 'ArrowRight') return forward;
    if (event.key === 'ArrowLeft') return -forward;
    return 0;
  }
}
