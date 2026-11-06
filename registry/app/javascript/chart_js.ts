// Chart.js, built as its own entry point rather than bundled into
// application.js, so a page without a chart never downloads it. Only the line,
// bar, pie and doughnut parts are registered, a fraction of the full build.
//
// Same shape as ag_grid.ts and cally.ts, and for the same reasons: a bun
// code-split chunk can't be used because Propshaft serves digested filenames,
// and the URL is handed to the Stimulus controller from Ruby.
import {
  ArcElement,
  BarController,
  BarElement,
  CategoryScale,
  Chart,
  DoughnutController,
  LinearScale,
  LineController,
  LineElement,
  PieController,
  PointElement,
  Tooltip,
} from 'chart.js';

Chart.register(
  ArcElement,
  BarController,
  BarElement,
  CategoryScale,
  DoughnutController,
  LinearScale,
  LineController,
  LineElement,
  PieController,
  PointElement,
  Tooltip,
);

export { Chart };
