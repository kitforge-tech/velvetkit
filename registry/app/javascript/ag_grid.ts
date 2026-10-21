// AG Grid, built as its own entry point rather than bundled into
// application.js. It is ~1.3 MB unminified — larger than the entire rest of
// the app — and only two screens use it, so it is loaded on demand by
// UI::DataGrid's Stimulus controller instead of on every page.
//
// It cannot be a bun code-split chunk: splitting emits sibling imports by
// plain filename, and Propshaft serves digested filenames, so every chunk
// 404s. A separate entry point stays self-contained, and Ruby hands the
// controller the digested URL to import.
export {
  createGrid,
  ModuleRegistry,
  InfiniteRowModelModule,
  // The register is a form: it holds one class, needs every row present to
  // submit, and pages nothing. That is the client-side model, not the
  // infinite one the read-only grids use.
  ClientSideRowModelModule,
  PaginationModule,
  TextFilterModule,
  NumberFilterModule,
  CustomFilterModule,
  ColumnAutoSizeModule,
  themeQuartz,
  colorSchemeDark,
  colorSchemeLight
} from "ag-grid-community";
