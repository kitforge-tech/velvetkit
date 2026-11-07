// Vanilla Calendar Pro, built as its own entry point rather than bundled into
// application.js, and loaded the first time a date picker opens. Its layout
// stylesheet and the light theme come out of the same build as
// vanilla_calendar.css; the kit points the theme's colours at its own tokens
// (velvetkit.css), so it follows dark mode.
//
// Same shape as ag_grid.ts and chart_js.ts: a bun code-split chunk can't be
// used because Propshaft serves digested filenames, so Ruby hands the
// controller both URLs.
import 'vanilla-calendar-pro/styles/layout.css';
import 'vanilla-calendar-pro/styles/layout/months.css';
import 'vanilla-calendar-pro/styles/themes/light.css';

// `months` is the extension that shows more than one month at once, for a range.
export { Calendar, months } from 'vanilla-calendar-pro';
