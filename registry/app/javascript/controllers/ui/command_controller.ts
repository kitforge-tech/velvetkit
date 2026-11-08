import { Controller } from '@hotwired/stimulus';
import { isApple, isTyping, matchesShortcut, parseShortcut, usableWhileTyping, type Shortcut } from './_internal/shortcut.js';

// Connects to data-controller="ui--command"
//
// A combobox over a listbox, as WAI-ARIA describes it: focus stays in the
// search box and the highlighted item is announced with aria-activedescendant.
//
// Typing hides the items that don't match and puts the best first, within
// their group. With a url, it also asks the server, the way UI::Select does:
// spaced out, a spinner when slow, nothing cancelled, answers remembered.
//
// With dialog, the panel lives in a native <dialog>: the shortcut toggles it
// from anywhere, and the platform gives the focus trap, Escape and the inert
// page behind it.
const SEARCH_DELAY = 200;
const SLOW_SEARCH = 200;
const REMEMBER_FOR = 60_000;

type Result = { label: string; value: string; href?: string; description?: string; group?: string };

const remembered = new Map<string, { at: number; results: Result[] }>();
const pending = new Map<string, Promise<Result[]>>();

type Turbo = { visit: (url: string) => void };

export default class extends Controller<HTMLElement> {
  static targets = ['dialog', 'panel', 'input', 'list', 'group', 'item', 'results', 'empty', 'status', 'template', 'searchIcon', 'spinner'];
  static values = {
    dialog: Boolean, shortcut: String, sortGroups: Boolean, url: String, param: { type: String, default: 'q' },
    resultsHeading: String, empty: String, searching: String, failed: String,
  };

  declare readonly hasDialogTarget: boolean;
  declare readonly dialogTarget: HTMLDialogElement;
  declare readonly inputTarget: HTMLInputElement;
  declare readonly listTarget: HTMLElement;
  declare readonly groupTargets: HTMLElement[];
  declare readonly itemTargets: HTMLElement[];
  declare readonly resultsTarget: HTMLElement;
  declare readonly emptyTarget: HTMLElement;
  declare readonly statusTarget: HTMLElement;
  declare readonly templateTarget: HTMLTemplateElement;
  declare readonly searchIconTarget: HTMLElement;
  declare readonly spinnerTarget: HTMLElement;
  declare readonly dialogValue: boolean;
  declare readonly shortcutValue: string;
  declare readonly sortGroupsValue: boolean;
  declare readonly urlValue: string;
  declare readonly paramValue: string;
  declare readonly resultsHeadingValue: string;
  declare readonly emptyValue: string;
  declare readonly searchingValue: string;
  declare readonly failedValue: string;

  private shortcuts: Shortcut[] = [];
  private apple = false;
  private highlighted: HTMLElement | null = null;
  private searchTimer?: number;
  private slowTimer?: number;
  private latestKey = '';
  private resultCount = 0;

  connect() {
    this.apple = isApple();
    this.itemTargets.forEach((item, index) => { item.dataset.order = String(index); });
    this.groupTargets.forEach((group, index) => { group.dataset.order = String(index); });
    if (this.dialogValue && this.hasDialogTarget) {
      this.shortcuts = this.shortcutValue.split(/\s+/).filter(Boolean).map(parseShortcut);
      if (this.shortcuts.length) document.addEventListener('keydown', this.onShortcut);
      this.dialogTarget.addEventListener('click', this.onBackdrop);
      this.dialogTarget.addEventListener('close', this.onClose);
    }
    this.filter('');
  }

  disconnect() {
    document.removeEventListener('keydown', this.onShortcut);
    if (this.hasDialogTarget) {
      this.dialogTarget.removeEventListener('click', this.onBackdrop);
      this.dialogTarget.removeEventListener('close', this.onClose);
      if (this.dialogTarget.open) this.dialogTarget.close();
    }
    this.stopSearch();
  }

  // ── Opening and closing (dialog) ─────────────────────────────────────────

  open(event?: Event) {
    event?.preventDefault();
    if (!this.hasDialogTarget || this.dialogTarget.open) return;

    this.inputTarget.value = '';
    this.filter('');
    this.dialogTarget.showModal();
    this.inputTarget.focus();
  }

  close() {
    if (this.hasDialogTarget && this.dialogTarget.open) this.dialogTarget.close();
  }

  private onShortcut = (event: KeyboardEvent) => {
    if (event.defaultPrevented || event.repeat || event.isComposing) return;
    const shortcut = this.shortcuts.find((s) => matchesShortcut(event, s, this.apple));
    if (!shortcut) return;
    // A bare-key shortcut, like "/", is typing when in a field, this search
    // box included: there it's a "/" in the query, not a way to close.
    if (isTyping(event.target) && !usableWhileTyping(shortcut)) return;

    event.preventDefault();
    if (this.dialogTarget.open) this.close();
    else this.open();
  };

  private onBackdrop = (event: MouseEvent) => {
    if (event.target === this.dialogTarget) this.close();
  };

  private onClose = () => {
    this.stopSearch();
  };

  // ── Typing ───────────────────────────────────────────────────────────────

  search() {
    const query = this.inputTarget.value.trim();
    this.filter(query);
    this.announce();
    if (!this.remote) return;

    window.clearTimeout(this.searchTimer);
    if (!query) {
      this.stopSearch();
      this.clearResults();
      this.updateEmpty();
      return;
    }
    this.searchTimer = window.setTimeout(() => this.fetchResults(query), SEARCH_DELAY);
  }

  // Hides what doesn't match, best matches first in each group; an empty
  // query puts everything back as written. With sortGroups, the groups follow
  // their best match too.
  private filter(query: string) {
    const words = query.toLowerCase().split(/\s+/).filter(Boolean);
    const best = new Map<HTMLElement, number>();

    this.groupTargets.forEach((group) => {
      const items = this.itemTargets.filter((item) => item.closest('[data-ui--command-target="group"]') === group);
      const scored = items.map((item) => ({ item, score: words.length ? this.score(item, words) : 1 }));
      scored.forEach(({ item, score }) => { item.hidden = score <= 0; });
      scored
        .sort((a, b) => (words.length ? b.score - a.score : 0) || Number(a.item.dataset.order) - Number(b.item.dataset.order))
        .forEach(({ item }) => group.append(item));
      group.hidden = scored.every(({ score }) => score <= 0);
      best.set(group, Math.max(0, ...scored.map(({ score }) => score)));
    });

    if (this.sortGroupsValue) {
      const results = this.resultsTarget;
      [...this.groupTargets]
        .sort((a, b) => (words.length ? best.get(b)! - best.get(a)! : 0) || Number(a.dataset.order) - Number(b.dataset.order))
        .forEach((group) => results.before(group));
    }

    this.updateEmpty();
    this.highlight(this.visible()[0] ?? null);
  }

  // Every word has to be found. A label starting with it beats a word in the
  // label starting with it, which beats it anywhere, which beats keywords,
  // which beats an abbreviation ("nwinv" for New invoice).
  private score(item: HTMLElement, words: string[]) {
    const label = (item.dataset.label ?? item.textContent ?? '').toLowerCase();
    const keywords = (item.dataset.keywords ?? '').toLowerCase();
    let total = 0;
    for (const word of words) {
      let best = 0;
      if (label.startsWith(word)) best = 1000 - label.length;
      else if (new RegExp(`(^|[\\s\\-_/.])${word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`).test(label)) best = 800 - label.length;
      else if (label.includes(word)) best = 600 - label.indexOf(word);
      else if (keywords.includes(word)) best = 400;
      else if (this.inOrder(label, word)) best = 100;
      if (best <= 0) return 0;
      total += best;
    }
    return total;
  }

  // An abbreviation: the letters in order, starting a word, each next one
  // later in the same word or starting another. "nwproj" is New project;
  // "dal" isn't hold this sale, since its d is in the middle of a word.
  private inOrder(text: string, word: string, from = 0, after = -1): boolean {
    if (word === '') return true;
    for (let at = text.indexOf(word[0], from); at !== -1; at = text.indexOf(word[0], at + 1)) {
      const startsWord = at === 0 || /[\s\-_/.,]/.test(text[at - 1]);
      const sameWord = after >= 0 && !/[\s\-_/.,]/.test(text.slice(after + 1, at));
      if ((startsWord || sameWord) && this.inOrder(text, word.slice(1), at + 1, at)) return true;
    }
    return false;
  }

  // ── Moving and picking ───────────────────────────────────────────────────

  navigate(event: KeyboardEvent) {
    const items = this.visible();
    const at = this.highlighted ? items.indexOf(this.highlighted) : -1;

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.highlight(items[(at + 1) % items.length] ?? null, true);
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.highlight(items[(at - 1 + items.length) % items.length] ?? null, true);
        break;
      case 'PageDown':
        event.preventDefault();
        this.highlight(items[Math.min(at + 8, items.length - 1)] ?? null, true);
        break;
      case 'PageUp':
        event.preventDefault();
        this.highlight(items[Math.max(at - 8, 0)] ?? null, true);
        break;
      case 'Enter':
        if (event.isComposing) return;
        event.preventDefault();
        if (this.highlighted) this.choose(this.highlighted, event.metaKey || event.ctrlKey);
        break;
      case 'Escape':
        // In a dialog, Escape closes it (the platform does that). On a page,
        // it clears the search first.
        if (!this.dialogValue && this.inputTarget.value) {
          event.preventDefault();
          this.inputTarget.value = '';
          this.search();
        }
        break;
    }
  }

  hover(event: PointerEvent) {
    const item = (event.target as HTMLElement).closest<HTMLElement>('[role="option"]');
    if (item && item !== this.highlighted && !item.hidden && item.getAttribute('aria-disabled') !== 'true') this.highlight(item);
  }

  pick(event: MouseEvent) {
    const item = (event.target as HTMLElement).closest<HTMLElement>('[role="option"]');
    if (!item) return;
    event.preventDefault();
    this.choose(item, event.metaKey || event.ctrlKey);
  }

  private choose(item: HTMLElement, newTab = false) {
    if (item.getAttribute('aria-disabled') === 'true') return;

    const detail = { value: item.dataset.value ?? '', label: item.dataset.label ?? '', href: item.dataset.href ?? null };
    const picked = this.dispatch('select', { detail, cancelable: true, target: item });
    if (picked.defaultPrevented) return;

    this.close();
    if (!detail.href) return;
    if (newTab) {
      window.open(detail.href, '_blank', 'noopener');
      return;
    }
    const turbo = (window as unknown as { Turbo?: Turbo }).Turbo;
    if (turbo) turbo.visit(detail.href);
    else window.location.assign(detail.href);
  }

  private highlight(item: HTMLElement | null, scroll = false) {
    this.highlighted?.removeAttribute('data-highlighted');
    this.highlighted?.setAttribute('aria-selected', 'false');
    this.highlighted = item;
    if (!item) {
      this.inputTarget.removeAttribute('aria-activedescendant');
      return;
    }
    item.setAttribute('data-highlighted', '');
    item.setAttribute('aria-selected', 'true');
    this.inputTarget.setAttribute('aria-activedescendant', item.id);
    if (scroll) item.scrollIntoView({ block: 'nearest' });
  }

  private visible() {
    return [...this.listTarget.querySelectorAll<HTMLElement>('[role="option"]')]
      .filter((item) => !item.hidden && !item.closest('[hidden]') && item.getAttribute('aria-disabled') !== 'true');
  }

  // For analytics and the like: what was searched and how much it found,
  // server results included once they're in.
  private announce() {
    const query = this.inputTarget.value.trim();
    const matches = [...this.listTarget.querySelectorAll<HTMLElement>('[role="option"]')]
      .filter((item) => !item.hidden && !item.closest('[hidden]')).length;
    this.dispatch('search', { detail: { query, matches } });
  }

  private updateEmpty() {
    const query = this.inputTarget.value.trim();
    const searching = this.listTarget.getAttribute('aria-busy') === 'true';
    // Disabled items count as found: they're shown, just not pickable.
    const shown = [...this.listTarget.querySelectorAll<HTMLElement>('[role="option"]')].filter((item) => !item.hidden && !item.closest('[hidden]'));
    const none = shown.length === 0 && !this.statusTarget.textContent;
    this.emptyTarget.textContent = this.emptyValue;
    this.emptyTarget.hidden = !(query && none && !searching);
  }

  // ── Searching the server ─────────────────────────────────────────────────

  private get remote() {
    return this.urlValue !== '';
  }

  private async fetchResults(query: string) {
    const url = new URL(this.urlValue, window.location.href);
    url.searchParams.set(this.paramValue, query);
    const key = url.toString();
    this.latestKey = key;
    window.clearTimeout(this.slowTimer);

    const known = remembered.get(key);
    if (known && Date.now() - known.at < REMEMBER_FOR) {
      this.showResults(known.results);
      return;
    }

    this.listTarget.setAttribute('aria-busy', 'true');
    this.slowTimer = window.setTimeout(() => this.showStatus(this.searchingValue, true), SLOW_SEARCH);
    try {
      const results = await this.ask(url, key);
      if (this.latestKey !== key) return;
      this.listTarget.removeAttribute('aria-busy');
      this.showResults(results);
      this.announce();
    } catch {
      if (this.latestKey !== key) return;
      this.listTarget.removeAttribute('aria-busy');
      this.clearResults();
      this.showStatus(this.failedValue);
      this.highlight(this.visible()[0] ?? null);
    }
  }

  private ask(url: URL, key: string): Promise<Result[]> {
    let request = pending.get(key);
    if (!request) {
      request = fetch(url, { headers: { Accept: 'application/json' } })
        .then((response) => {
          if (!response.ok) throw new Error(`${response.status}`);
          return response.json();
        })
        .then((data) => {
          const results = this.normalise(data);
          remembered.set(key, { at: Date.now(), results });
          return results;
        })
        .finally(() => pending.delete(key));
      pending.set(key, request);
    }
    return request;
  }

  private normalise(data: unknown): Result[] {
    if (!Array.isArray(data)) return [];
    return data.flatMap((item) => {
      if (!item || typeof item !== 'object') return [];
      const { label, value, href, url, description, group } = item as Record<string, unknown>;
      const link = href ?? url;
      const text = String(label ?? value ?? '');
      if (!text) return [];
      return [{
        label: text, value: String(value ?? link ?? text), href: link ? String(link) : undefined,
        description: description ? String(description) : undefined, group: group ? String(group) : undefined,
      }];
    });
  }

  // Server results go after what's on the page, grouped as the server says.
  private showResults(results: Result[]) {
    this.clearResults();
    this.showStatus(null);
    const groups = new Map<string, Result[]>();
    results.forEach((result) => {
      const heading = result.group || this.resultsHeadingValue;
      groups.set(heading, [...(groups.get(heading) ?? []), result]);
    });

    groups.forEach((list, heading) => {
      const group = document.createElement('div');
      group.setAttribute('role', 'group');
      group.className = 'py-1 [&:not(:first-child)]:border-t';
      const title = document.createElement('div');
      title.id = `${this.listTarget.id}-results-${this.resultCount++}`;
      title.className = 'px-2 pt-1.5 pb-1 text-xs font-medium text-muted-foreground';
      title.textContent = heading;
      group.setAttribute('aria-labelledby', title.id);
      group.append(title);
      list.forEach((result) => group.append(this.buildItem(result)));
      this.resultsTarget.append(group);
    });

    this.updateEmpty();
    // Keep the highlight on what's on the page if something there matched.
    if (!this.highlighted || this.highlighted.hidden) this.highlight(this.visible()[0] ?? null);
  }

  private buildItem(result: Result) {
    const item = this.templateTarget.content.firstElementChild!.cloneNode(true) as HTMLElement;
    item.id = `${this.listTarget.id}-result-${this.resultCount++}`;
    item.removeAttribute('data-ui--command-target');
    item.dataset.value = result.value;
    item.dataset.label = result.label;
    if (result.href) item.dataset.href = result.href;
    const body = item.querySelector<HTMLElement>('span.flex-col')!;
    body.firstElementChild!.textContent = result.label;
    if (result.description) {
      const description = document.createElement('span');
      description.className = 'truncate text-xs text-muted-foreground';
      description.textContent = result.description;
      body.append(description);
    }
    return item;
  }

  private clearResults() {
    if (this.highlighted && this.resultsTarget.contains(this.highlighted)) this.highlight(null);
    this.resultsTarget.replaceChildren();
  }

  private showStatus(text: string | null, busy = false) {
    window.clearTimeout(this.slowTimer);
    this.statusTarget.textContent = text ?? '';
    this.statusTarget.hidden = !text;
    // While searching, the spinner says it; the words are for screen readers.
    this.statusTarget.classList.toggle('sr-only', busy);
    this.spinnerTarget.classList.toggle('hidden', !busy);
    this.spinnerTarget.classList.toggle('flex', busy);
    this.searchIconTarget.classList.toggle('hidden', busy);
    this.searchIconTarget.classList.toggle('flex', !busy);
    this.updateEmpty();
  }

  private stopSearch() {
    window.clearTimeout(this.searchTimer);
    window.clearTimeout(this.slowTimer);
    this.latestKey = '';
    this.listTarget.removeAttribute('aria-busy');
    this.showStatus(null);
  }
}
