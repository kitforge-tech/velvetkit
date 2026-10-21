// Cally, built as its own entry point rather than bundled into
// application.js. A date picker is only wanted on data-entry screens, and the
// class list should not pay 9 KB for one.
//
// Same shape as ag_grid.ts, and for the same reasons: a bun code-split chunk
// cannot be used because Propshaft serves digested filenames, and the URL is
// handed to the Stimulus controller from Ruby.
import "cally";
