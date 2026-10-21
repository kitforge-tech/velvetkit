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

// Turbo replaces markup without a full page load, so icons are drawn again
// after every kind of render, not just the first.
[
  'turbo:load',
  'turbo:frame-load',
  'turbo:render',
  'turbo:submit-end',
  'turbo:render-stream',
].forEach((event) => document.addEventListener(event, () => createIcons({ icons })));
