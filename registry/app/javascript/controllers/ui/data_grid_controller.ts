import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="ui--data-grid"
//
// The grid holds one page at a time. Each page — and each sort or filter the
// user applies — is a request to the server, which does the work in Postgres
// against the whole table. Filtering in the browser would only ever see the
// page the browser was sent.
//
// AG Grid is ~365 KB gzipped, several times the rest of the application, so it
// is built as its own entry point (app/javascript/ag_grid.ts) and imported at
// connect time. A page without a grid never downloads it.
//
// The URL is passed in from Ruby rather than written here, because Propshaft
// serves digested filenames. Importing a variable also stops the bundler
// resolving it statically and folding AG Grid back into application.js.
// turbo-rails installs Turbo on window from application.ts. Importing it here
// instead would bundle a second copy into this entry point, and two Turbo
// instances means two sets of event listeners on every navigation.
declare global {
  interface Window {
    Turbo?: { visit: (url: string) => void };
  }
}

type ColumnSpec = {
  field: string;
  headerName: string;
  width?: number;
  type?: 'text' | 'number';
  sortable: boolean;
  filterable: boolean;
};

type GridRequest = {
  startRow: number;
  endRow: number;
  sortModel: unknown[];
  filterModel: Record<string, unknown>;
  successCallback: (rows: unknown[], lastRow: number) => void;
  failCallback: () => void;
};

export default class extends Controller<HTMLElement> {
  static values = {
    url: String,
    columns: Array,
    pageSize: { type: Number, default: 15 },
    emptyMessage: { type: String, default: 'Nothing to show' },
    moduleUrl: String,
  };

  declare readonly urlValue: string;
  declare readonly columnsValue: ColumnSpec[];
  declare readonly pageSizeValue: number;
  declare readonly emptyMessageValue: string;
  declare readonly moduleUrlValue: string;

  private grid?: {
    destroy: () => void;
    setGridOption: (key: string, value: unknown) => void;
    paginationGetPageSize: () => number;
  };

  async connect() {
    const {
      createGrid,
      ModuleRegistry,
      InfiniteRowModelModule,
      PaginationModule,
      TextFilterModule,
      NumberFilterModule,
      CustomFilterModule,
      ColumnAutoSizeModule,
      themeQuartz,
    } = await import(this.moduleUrlValue);

    ModuleRegistry.registerModules([
      InfiniteRowModelModule,
      PaginationModule,
      TextFilterModule,
      NumberFilterModule,
      CustomFilterModule,
      ColumnAutoSizeModule,
    ]);

    // The grid paints its own surface, so it is pointed at the app's design
    // tokens rather than AG Grid's palette. Because these are the same CSS
    // variables the rest of the page uses, switching to dark mode re-themes
    // the grid with no JavaScript involved.
    const theme = themeQuartz.withParams({
      backgroundColor: 'var(--card)',
      foregroundColor: 'var(--card-foreground)',
      borderColor: 'var(--border)',
      chromeBackgroundColor: 'var(--muted)',
      // The header stays neutral; the primary colour shows in the sort and
      // filter controls and in hover and selection, where it marks what the
      // user is doing rather than tinting the whole chrome.
      headerTextColor: 'var(--foreground)',
      accentColor: 'var(--primary)',
      rowHoverColor: 'color-mix(in oklab, var(--primary) 7%, transparent)',
      selectedRowBackgroundColor: 'color-mix(in oklab, var(--primary) 12%, transparent)',
      oddRowBackgroundColor: 'color-mix(in oklab, var(--muted-foreground) 6%, transparent)',
      inputBackgroundColor: 'var(--background)',
      inputBorder: { color: 'var(--input)' },
      fontFamily: 'inherit',
      fontSize: '14px',
      headerFontSize: '14px',
      headerFontWeight: 500,
      wrapperBorderRadius: 'var(--radius-lg)',
      borderRadius: 'var(--radius-sm)',
      rowHeight: '36px',
      cellFontFamily: 'inherit',
      headerHeight: '36px',
      cellHorizontalPadding: '12px',
    });

    this.grid = createGrid(this.element, {
      theme,
      columnDefs: this.columnsValue.map((column) => ({
        field: column.field,
        headerName: column.headerName,
        width: column.width,
        flex: column.width ? undefined : 1,
        sortable: column.sortable,
        filter: column.filterable
          ? column.type === 'number'
            ? 'agNumberColumnFilter'
            : 'agTextColumnFilter'
          : false,
        // Every filter is a round trip, so it waits for a pause in typing
        // rather than firing per keystroke.
        filterParams: { debounceMs: 400, buttons: ['reset'] },
        resizable: true,
      })),
      rowModelType: 'infinite',
      datasource: { getRows: this.fetchRows.bind(this) },
      // One request per page: the block the grid caches is the page it shows.
      cacheBlockSize: this.pageSizeValue,
      pagination: true,
      paginationPageSize: this.pageSizeValue,
      paginationPageSizeSelector: [15, 25, 50, 100],
      // Changing the page size has to change the block size with it, or the
      // grid asks for pages the server was never told about.
      onPaginationChanged: () => {
        const size = this.grid?.paginationGetPageSize();
        if (size && size !== this.blockSize) {
          this.blockSize = size;
          this.grid?.setGridOption('cacheBlockSize', size);
        }
      },
      overlayNoRowsTemplate: `<span class="text-sm text-muted-foreground">${this.emptyMessageValue}</span>`,
      // A row is clickable when the server sent a path with it, so which
      // screens open a record is decided in Ruby rather than here.
      onRowClicked: (event: { data?: { _path?: string }; event?: Event }) => {
        const path = event.data?._path;
        if (!path) return;

        // A click on a link or button inside a cell is that control's, not
        // the row's.
        const target = event.event?.target as HTMLElement | null;
        if (target?.closest('a, button, input')) return;

        window.Turbo?.visit(path);
      },
    });
  }

  disconnect() {
    this.grid?.destroy();
    this.grid = undefined;
  }

  private blockSize = 0;

  private async fetchRows(params: GridRequest) {
    const query = new URLSearchParams({
      startRow: String(params.startRow),
      endRow: String(params.endRow),
      sortModel: JSON.stringify(params.sortModel),
      filterModel: JSON.stringify(params.filterModel),
    });

    try {
      const response = await fetch(`${this.urlValue}?${query}`, {
        headers: { Accept: 'application/json' },
      });
      if (!response.ok) throw new Error(`${response.status}`);

      const { rows, total } = await response.json();
      // The total is what lets the grid show a page count rather than an
      // endless scroll.
      params.successCallback(rows, total);
    } catch {
      params.failCallback();
    }
  }
}
