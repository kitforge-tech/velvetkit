// Lucide icons for VelvetKit components.
//
// The Icon component renders `<i data-lucide="name">`; createIcons swaps each
// one for its SVG. Only the icons listed here are bundled, so an icon your
// own views use has to be added in BOTH places below — one only in the import
// list renders as an empty element with a console warning and no error.
import {
  createIcons,
  Calendar,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronsUpDown,
  CircleAlert,
  CircleCheck,
  Ellipsis,
  Eye,
  EyeOff,
  Info,
  Loader,
  Mail,
  Monitor,
  Moon,
  PanelLeft,
  Sun,
  X,
} from 'lucide';

const icons = {
  Calendar,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronsUpDown,
  CircleAlert,
  CircleCheck,
  Ellipsis,
  Eye,
  EyeOff,
  Info,
  Loader,
  Mail,
  Monitor,
  Moon,
  PanelLeft,
  Sun,
  X,
};

// Icons are drawn whenever one is added to the page, however it arrives: a
// Turbo visit, frame or stream, or a controller's own markup. Only <i> is
// watched: the SVG that replaces it keeps data-lucide, and drawing on that
// would draw forever.
const draw = () => createIcons({ icons });
const added = (records: MutationRecord[]) =>
  records.some((record) =>
    Array.from(record.addedNodes).some(
      (node) => node instanceof Element && (node.matches('i[data-lucide]') || node.querySelector('i[data-lucide]') !== null),
    ),
  );

draw();
new MutationObserver((records) => added(records) && draw()).observe(document.documentElement, {
  childList: true,
  subtree: true,
});
