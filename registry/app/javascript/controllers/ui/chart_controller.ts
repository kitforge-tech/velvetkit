import { Controller } from '@hotwired/stimulus';
import type { Chart as ChartType, ChartConfiguration, ChartDataset, Plugin, TooltipModel } from 'chart.js';

// Connects to data-controller="ui--chart"
//
// Chart.js arrives from its own bundle (app/javascript/chart_js.ts) when the
// first chart on a page connects, so other pages never download it. Everything
// it draws takes its colours from the theme's CSS variables, read again when
// the theme changes, and the values in the tooltip are the ones Ruby wrote out,
// so they match the table.
//
// A chart is drawn when it scrolls into view, so its entrance is seen: bars
// grow from the baseline one after another, a line draws itself from left to
// right, and a pie sweeps round. Nothing moves for anyone who asks for reduced
// motion.
type Series = { name: string; color: number; data: (number | null)[]; text: string[]; colors?: number[]; shares?: string[] };
type AxisFormat = { style: 'number' | 'currency' | 'percent'; locale: string; unit: string; pattern: string };
type Config = {
  type: 'line' | 'bar' | 'pie' | 'donut';
  stacked: boolean;
  labels: string[];
  series: Series[];
  axis: AxisFormat;
  total?: string;
  total_label?: string;
};
type Theme = { series: string[]; hovered: string[]; surface: string; grid: string; muted: string; text: string; font: string };

const BAR_THICKNESS = 24;
const BAR_RADIUS = 4;
const SURFACE_GAP = 2;
const LINE_WIDTH = 2;
const POINT_RADIUS = 5;
const HIT_RADIUS = 12;
const END_LABEL_GAP = 8;
const END_LABEL_HEIGHT = 16;
const TICK_SIZE = 12;
const COMPACT_FROM = 10_000;
const BAR_GROW_MS = 600;
const SWEEP_MS = 800;
const DONUT_HOLE = '62%';
const SLICE_LIFT = 6;
const BAR_STAGGER_MS = 360;
const LINE_DRAW_MS = 900;
const VISIBLE_AT = 0.2;
const HOVER_MS = 150;
// How far the crosshair closes on its point each frame, so it slides there.
const CROSSHAIR_EASE = 0.3;

let chartModule: Promise<{ Chart: typeof ChartType }> | null = null;

export default class extends Controller<HTMLElement> {
  static targets = ['canvas', 'tooltip'];
  static values = { config: Object, moduleUrl: String };

  declare readonly canvasTarget: HTMLCanvasElement;
  declare readonly tooltipTarget: HTMLElement;
  declare readonly configValue: Config;
  declare readonly moduleUrlValue: string;

  private chart?: ChartType;
  private theme?: Theme;
  private themeWatcher?: MutationObserver;
  private schemeQuery?: MediaQueryList;
  private focusIndex = -1;
  private visibility?: IntersectionObserver;
  private revealed = false;
  private reveal = 1;
  private revealFrame?: number;
  private crosshairX: number | null = null;
  private crosshairFrame?: number;

  // Chart.js starts downloading at once; the chart waits to be on screen.
  connect() {
    chartModule ??= import(this.moduleUrlValue);
    if (!('IntersectionObserver' in window)) {
      this.draw();
      return;
    }

    this.visibility = new IntersectionObserver((entries) => {
      if (!entries.some((entry) => entry.isIntersecting)) return;

      this.visibility?.disconnect();
      this.draw();
    }, { threshold: VISIBLE_AT });
    this.visibility.observe(this.element);
  }

  private async draw() {
    const { Chart } = await chartModule!;
    if (!this.element.isConnected || this.chart) return;

    this.theme = this.readTheme();
    this.chart = new Chart(this.canvasTarget, this.chartConfig());
    if (this.configValue.type === 'line') this.drawLineIn();
    this.themeWatcher = new MutationObserver(this.retheme);
    this.themeWatcher.observe(document.documentElement, { attributes: true, attributeFilter: ['class', 'data-theme'] });
    this.schemeQuery = window.matchMedia('(prefers-color-scheme: dark)');
    this.schemeQuery.addEventListener('change', this.retheme);
  }

  disconnect() {
    this.visibility?.disconnect();
    if (this.revealFrame) cancelAnimationFrame(this.revealFrame);
    if (this.crosshairFrame) cancelAnimationFrame(this.crosshairFrame);
    this.themeWatcher?.disconnect();
    this.schemeQuery?.removeEventListener('change', this.retheme);
    this.chart?.destroy();
    this.chart = undefined;
  }

  // ── Keyboard ─────────────────────────────────────────────────────────────

  // The arrow keys step through the points, showing the same tooltip as hover.
  keydown(event: KeyboardEvent) {
    const last = this.configValue.labels.length - 1;
    const index = { ArrowRight: this.focusIndex + 1, ArrowLeft: this.focusIndex - 1, Home: 0, End: last }[event.key];
    if (index === undefined || !this.chart) {
      if (event.key === 'Escape') this.blur();
      return;
    }

    event.preventDefault();
    this.focusIndex = Math.max(0, Math.min(last, index));
    const active = this.configValue.series
      .map((_, datasetIndex) => ({ datasetIndex, index: this.focusIndex }))
      .filter(({ datasetIndex }) => this.configValue.series[datasetIndex].data[this.focusIndex] !== null);
    const point = this.chart.getDatasetMeta(active[0]?.datasetIndex ?? 0).data[this.focusIndex];
    this.chart.setActiveElements(active);
    this.chart.tooltip?.setActiveElements(active, { x: point?.x ?? 0, y: point?.y ?? 0 });
    this.chart.update('none');
  }

  blur() {
    this.focusIndex = -1;
    if (!this.chart) return;

    this.chart.setActiveElements([]);
    this.chart.tooltip?.setActiveElements([], { x: 0, y: 0 });
    this.chart.update('none');
  }

  // ── Building the chart ───────────────────────────────────────────────────

  private chartConfig(): ChartConfiguration {
    const { type, stacked, labels } = this.configValue;
    const theme = this.theme!;
    const shared = {
      responsive: true,
      maintainAspectRatio: false,
      animation: this.entrance(),
      // Hovered points grow, and hovered bars and slices lighten, over a moment.
      transitions: this.reducedMotion ? {} : { active: { animation: { duration: HOVER_MS } } },
      font: { family: theme.font },
      plugins: {
        legend: { display: false },
        tooltip: { enabled: false, external: (context: { tooltip: TooltipModel<'line' | 'bar'> }) => this.drawTooltip(context.tooltip) },
      },
    };

    if (this.circular) {
      return {
        type: type === 'donut' ? 'doughnut' : 'pie',
        data: { labels, datasets: this.datasets() },
        options: {
          ...shared,
          cutout: type === 'donut' ? DONUT_HOLE : 0,
          layout: { padding: SLICE_LIFT + 2 },
          interaction: { mode: 'nearest', intersect: true },
        },
        plugins: type === 'donut' ? [this.donutTotal()] : [],
      } as unknown as ChartConfiguration;
    }

    return {
      type,
      data: { labels, datasets: this.datasets() },
      options: {
        ...shared,
        interaction: { mode: 'index', intersect: false },
        layout: { padding: { top: 8, right: type === 'line' ? this.endLabelRoom() : 0 } },
        scales: {
          x: {
            stacked,
            grid: { display: false },
            border: { color: theme.grid },
            ticks: { color: theme.muted, font: { family: theme.font, size: TICK_SIZE }, maxRotation: 0, autoSkipPadding: 12 },
          },
          y: {
            stacked,
            beginAtZero: true,
            grid: { color: theme.grid, lineWidth: 1, drawTicks: false },
            border: { display: false },
            ticks: {
              color: theme.muted,
              padding: 8,
              maxTicksLimit: 6,
              font: { family: theme.font, size: TICK_SIZE },
              callback: (value: number | string) => this.axisText(Number(value)),
            },
          },
        },
      },
      plugins: type === 'line' ? [this.lineReveal(), this.crosshair(), this.endLabels()] : [],
    } as unknown as ChartConfiguration;
  }

  private get circular(): boolean {
    return this.configValue.type === 'pie' || this.configValue.type === 'donut';
  }

  private datasets(): ChartDataset[] {
    const theme = this.theme!;
    if (this.circular) {
      // A slice per label, each its own colour, parted by a gap in the surface
      // colour. A hovered slice lifts out a little.
      const series = this.configValue.series[0];
      const colors = series.colors ?? [];
      return [{
        label: series.name,
        data: series.data,
        backgroundColor: colors.map((color) => theme.series[color - 1]),
        hoverBackgroundColor: colors.map((color) => theme.hovered[color - 1]),
        borderColor: theme.surface,
        hoverBorderColor: theme.surface,
        borderWidth: SURFACE_GAP,
        hoverOffset: SLICE_LIFT,
      } as unknown as ChartDataset];
    }

    return this.configValue.series.map((series, index) => {
      const color = theme.series[series.color - 1];
      if (this.configValue.type === 'line') {
        return {
          label: series.name,
          data: series.data,
          borderColor: color,
          backgroundColor: color,
          borderWidth: LINE_WIDTH,
          borderCapStyle: 'round',
          borderJoinStyle: 'round',
          tension: 0,
          pointRadius: 0,
          pointHoverRadius: POINT_RADIUS,
          pointHoverBorderWidth: SURFACE_GAP,
          pointHoverBorderColor: theme.surface,
          pointHoverBackgroundColor: color,
          pointHitRadius: HIT_RADIUS,
        } as ChartDataset<'line'>;
      }
      return {
        label: series.name,
        data: series.data,
        backgroundColor: color,
        hoverBackgroundColor: theme.hovered[series.color - 1],
        maxBarThickness: BAR_THICKNESS,
        categoryPercentage: 0.7,
        barPercentage: 0.9,
        borderSkipped: 'start',
        borderRadius: (context: { dataIndex: number }) => (this.isOuterBar(index, context.dataIndex) ? BAR_RADIUS : 0),
        // A surface-coloured edge on each stacked segment is the gap between them.
        borderWidth: this.configValue.stacked ? { top: SURFACE_GAP } : 0,
        borderColor: theme.surface,
      } as unknown as ChartDataset<'bar'>;
    });
  }

  // Only the end of a stack is rounded; the segments under it stay square.
  private isOuterBar(datasetIndex: number, index: number): boolean {
    if (!this.configValue.stacked) return true;

    const value = this.configValue.series[datasetIndex].data[index] ?? 0;
    const outer = this.configValue.series
      .map((series, i) => ({ i, value: series.data[index] ?? 0 }))
      .filter((entry) => entry.value !== 0 && Math.sign(entry.value) === Math.sign(value))
      .pop();
    return outer?.i === datasetIndex;
  }

  // ── Entrance ─────────────────────────────────────────────────────────────

  // Bars grow from the baseline, left to right, the whole run taking about a
  // second however many there are. A line draws itself instead (drawLineIn), so
  // its data doesn't animate, though hovering still does.
  private entrance() {
    if (this.reducedMotion) return false;
    if (this.configValue.type === 'line') return { duration: 0 };
    if (this.circular) return { duration: SWEEP_MS, easing: 'easeOutQuart' as const, animateRotate: true, animateScale: false };

    const step = BAR_STAGGER_MS / Math.max(1, this.configValue.labels.length - 1);
    return {
      duration: BAR_GROW_MS,
      easing: 'easeOutQuart' as const,
      onComplete: () => {
        this.revealed = true;
      },
      delay: (context: { type: string; mode: string; dataIndex: number }) =>
        context.type === 'data' && context.mode === 'default' && !this.revealed ? context.dataIndex * step : 0,
    };
  }

  // Uncovers the lines from left to right, easing out.
  private drawLineIn() {
    if (this.reducedMotion) return;

    const start = performance.now();
    this.reveal = 0;
    const frame = (now: number) => {
      const t = Math.min(1, (now - start) / LINE_DRAW_MS);
      this.reveal = 1 - (1 - t) ** 3;
      this.chart?.draw();
      this.revealFrame = t < 1 ? requestAnimationFrame(frame) : undefined;
    };
    this.revealFrame = requestAnimationFrame(frame);
  }

  // ── Plugins ──────────────────────────────────────────────────────────────

  // Clips the lines to the part drawn so far. Registered first, so the clip is
  // lifted before the crosshair and end labels draw.
  private lineReveal(): Plugin {
    return {
      id: 'uiLineReveal',
      beforeDatasetsDraw: (chart) => {
        if (this.reveal >= 1) return;

        const { ctx, chartArea } = chart;
        ctx.save();
        ctx.beginPath();
        ctx.rect(0, 0, chartArea.left + (chartArea.right - chartArea.left) * this.reveal, chart.height);
        ctx.clip();
      },
      afterDatasetsDraw: (chart) => {
        if (this.reveal < 1) chart.ctx.restore();
      },
    };
  }

  // The total, in the middle of a donut, sized to fit its hole.
  private donutTotal(): Plugin {
    return {
      id: 'uiDonutTotal',
      afterDatasetsDraw: (chart) => {
        const arc = chart.getDatasetMeta(0).data[0] as unknown as { x: number; y: number; innerRadius: number } | undefined;
        if (!arc || !this.configValue.total) return;

        const { ctx } = chart;
        const size = Math.max(12, Math.min(24, arc.innerRadius * 0.32));
        ctx.save();
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillStyle = this.theme!.text;
        ctx.font = `600 ${size}px ${this.theme!.font}`;
        ctx.fillText(this.configValue.total, arc.x, arc.y - size * 0.35);
        ctx.fillStyle = this.theme!.muted;
        ctx.font = `400 ${TICK_SIZE}px ${this.theme!.font}`;
        ctx.fillText(this.configValue.total_label ?? '', arc.x, arc.y + size * 0.6);
        ctx.restore();
      },
    };
  }

  // A hairline down the chart at the point being read. Moving to the next
  // point, it slides across instead of jumping.
  private crosshair(): Plugin {
    return {
      id: 'uiCrosshair',
      afterDatasetsDraw: (chart) => {
        const active = chart.getActiveElements()[0];
        if (!active) {
          this.crosshairX = null;
          return;
        }

        const target = active.element.x;
        const x = this.crosshairX === null || this.reducedMotion
          ? target
          : this.crosshairX + (target - this.crosshairX) * CROSSHAIR_EASE;
        this.crosshairX = Math.abs(target - x) < 0.5 ? target : x;
        if (this.crosshairX !== target && !this.crosshairFrame) {
          this.crosshairFrame = requestAnimationFrame(() => {
            this.crosshairFrame = undefined;
            chart.draw();
          });
        }

        const { ctx, chartArea } = chart;
        ctx.save();
        ctx.strokeStyle = this.theme!.muted;
        ctx.globalAlpha = 0.5;
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(Math.round(this.crosshairX) + 0.5, chartArea.top);
        ctx.lineTo(Math.round(this.crosshairX) + 0.5, chartArea.bottom);
        ctx.stroke();
        ctx.restore();
      },
    };
  }

  // Each line's last value, beside its end. Labels that would overlap one
  // already placed are left out rather than nudged away from their line; the
  // legend, tooltip and table still have them.
  private endLabels(): Plugin {
    return {
      id: 'uiEndLabels',
      afterDatasetsDraw: (chart) => {
        const { ctx } = chart;
        const placed: number[] = [];
        ctx.save();
        // They appear as the line reaches them, over its last fifth.
        ctx.globalAlpha = Math.max(0, (this.reveal - 0.8) / 0.2);
        ctx.font = `500 ${TICK_SIZE}px ${this.theme!.font}`;
        ctx.fillStyle = this.theme!.text;
        ctx.textBaseline = 'middle';
        this.configValue.series.forEach((series, datasetIndex) => {
          const last = this.lastIndex(series);
          if (last < 0) return;

          const point = chart.getDatasetMeta(datasetIndex).data[last];
          if (!point || placed.some((y) => Math.abs(y - point.y) < END_LABEL_HEIGHT)) return;

          placed.push(point.y);
          ctx.fillText(series.text[last], point.x + END_LABEL_GAP, point.y);
        });
        ctx.restore();
      },
    };
  }

  private lastIndex(series: Series): number {
    for (let i = series.data.length - 1; i >= 0; i--) if (series.data[i] !== null) return i;
    return -1;
  }

  // Room on the right for the widest end label.
  private endLabelRoom(): number {
    const context = document.createElement('canvas').getContext('2d');
    if (!context) return 0;

    context.font = `500 ${TICK_SIZE}px ${this.theme!.font}`;
    const widths = this.configValue.series.map((series) => {
      const last = this.lastIndex(series);
      return last < 0 ? 0 : context.measureText(series.text[last]).width;
    });
    return Math.ceil(Math.max(0, ...widths) + END_LABEL_GAP * 2);
  }

  // ── Tooltip ──────────────────────────────────────────────────────────────

  // The value leads and the series name follows, keyed by a short stroke of
  // its colour. Built with textContent: names come from the app's data.
  private drawTooltip(tooltip: TooltipModel<'line' | 'bar'>) {
    const box = this.tooltipTarget;
    if (tooltip.opacity === 0 || tooltip.dataPoints.length === 0) {
      box.removeAttribute('data-shown');
      return;
    }

    const index = tooltip.dataPoints[0].dataIndex;
    const title = document.createElement('p');
    title.className = 'mb-1 text-muted-foreground';
    title.textContent = this.configValue.labels[index];
    const rows = tooltip.dataPoints.map((point) => {
      const series = this.configValue.series[point.datasetIndex];
      const row = document.createElement('p');
      row.className = 'flex items-center gap-2 whitespace-nowrap';
      const key = document.createElement('span');
      key.className = 'h-0.5 w-3 shrink-0 rounded-full';
      const color = series.colors ? series.colors[point.dataIndex] : series.color;
      key.style.background = this.theme!.series[color - 1];
      const value = document.createElement('span');
      value.className = 'font-semibold tabular-nums text-foreground';
      value.textContent = series.text[point.dataIndex];
      const name = document.createElement('span');
      name.className = 'text-muted-foreground';
      // A slice's share says more than the series' name, which is the same for every slice.
      name.textContent = series.shares ? series.shares[point.dataIndex] : series.name;
      row.append(key, value, name);
      return row;
    });
    box.replaceChildren(title, ...rows);
    const appearing = !box.hasAttribute('data-shown');

    // Beside the point, on whichever side has room.
    const gap = 12;
    const frame = this.canvasTarget.parentElement!.getBoundingClientRect();
    const left = tooltip.caretX + gap + box.offsetWidth > frame.width ? tooltip.caretX - gap - box.offsetWidth : tooltip.caretX + gap;
    const top = Math.min(Math.max(0, tooltip.caretY - box.offsetHeight / 2), frame.height - box.offsetHeight);
    const place = `translate(${Math.max(0, left)}px, ${Math.max(0, top)}px)`;
    // Appearing, it fades in where it is; only moving between points glides.
    if (appearing) {
      box.style.transition = 'none';
      box.style.transform = place;
      void box.offsetWidth;
      box.style.transition = '';
      box.setAttribute('data-shown', '');
    } else {
      box.style.transform = place;
    }
  }

  // ── Numbers ──────────────────────────────────────────────────────────────

  private axisText(value: number): string {
    const { style, locale, unit, pattern } = this.configValue.axis;
    const number = new Intl.NumberFormat(locale, Math.abs(value) >= COMPACT_FROM ? { notation: 'compact', maximumFractionDigits: 1 } : {})
      .format(Math.abs(value));
    const sign = value < 0 ? '-' : '';
    if (style === 'percent') return `${sign}${number}%`;
    if (style === 'currency') return sign + pattern.replace('%u', unit).replace('%n', number);
    return sign + number;
  }

  // ── Theme ────────────────────────────────────────────────────────────────

  private retheme = () => {
    if (!this.chart) return;

    this.theme = this.readTheme();
    const theme = this.theme;
    this.chart.data.datasets = this.datasets();
    const scales = (this.chart.options.scales ?? {}) as Record<string, { grid?: { color?: string }; border?: { color?: string }; ticks?: { color?: string } }>;
    for (const scale of Object.values(scales)) {
      if (scale.grid) scale.grid.color = theme.grid;
      if (scale.border) scale.border.color = theme.grid;
      if (scale.ticks) scale.ticks.color = theme.muted;
    }
    this.chart.update('none');
  };

  // Every colour as the canvas needs it, from the CSS variables in effect here.
  private readTheme(): Theme {
    const style = getComputedStyle(this.element);
    const surface = this.surfaceColor();
    // A see-through token (dark mode's border is white at 10%) is laid over the
    // surface, since the canvas is given solid colours.
    const token = (name: string) => {
      const color = this.toRgb(style.getPropertyValue(name).trim());
      return color[3] < 255 ? this.mix(surface, color, color[3] / 255) : color;
    };
    const series = [1, 2, 3, 4, 5].map((n) => token(`--chart-${n}`));
    return {
      series: series.map((color) => this.rgbString(color)),
      hovered: series.map((color) => this.rgbString(this.mix(color, surface, 0.2))),
      surface: this.rgbString(surface),
      grid: this.rgbString(token('--border')),
      muted: this.rgbString(token('--muted-foreground')),
      text: this.rgbString(token('--foreground')),
      font: style.fontFamily,
    };
  }

  // What the chart is drawn on: the nearest background that isn't see-through.
  private surfaceColor(): number[] {
    for (let element: Element | null = this.element; element; element = element.parentElement) {
      const color = this.toRgb(getComputedStyle(element).backgroundColor);
      if (color[3] > 0) return color;
    }
    return this.toRgb(getComputedStyle(document.body).getPropertyValue('--background').trim() || '#fff');
  }

  // Any CSS colour (oklch, hex, color-mix) to RGBA, by painting one pixel.
  private toRgb(color: string): number[] {
    const context = document.createElement('canvas').getContext('2d', { willReadFrequently: true });
    if (!context || !color) return [0, 0, 0, 255];

    context.fillStyle = color;
    context.fillRect(0, 0, 1, 1);
    return Array.from(context.getImageData(0, 0, 1, 1).data);
  }

  private mix(color: number[], other: number[], amount: number): number[] {
    return color.map((channel, i) => (i === 3 ? 255 : Math.round(channel * (1 - amount) + other[i] * amount)));
  }

  private rgbString([r, g, b]: number[]): string {
    return `rgb(${r}, ${g}, ${b})`;
  }

  private get reducedMotion(): boolean {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }
}
