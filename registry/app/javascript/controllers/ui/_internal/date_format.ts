// Typed dates in the locale's order, and ISO dates for the form, shared by the
// date picker and the date range picker.
//
// The order ("DMY") and separator come from Ruby, which derives them from
// date.formats.typed in the locale, so one string governs what a date field
// accepts, shows and hints at.
const ISO = /^(\d{4})-(\d{2})-(\d{2})$/;
// Any of / - . or a space between the parts: people type what is in front of
// them, and being strict about the separator only creates work.
const PARTS = /^(\d{1,4})[/\-. ](\d{1,4})[/\-. ](\d{1,4})$/;

// The locale's order in, ISO out. Rejects 31/02 rather than rolling it into
// the 3rd of March, which is what Date does and how a wrong date gets stored
// without anyone seeing an error.
export function toIso(typed: string, order: string): string | null {
  const match = PARTS.exec(typed.trim());
  if (!match) return null;

  const parts = order.split('');
  const day = match[parts.indexOf('D') + 1];
  const month = match[parts.indexOf('M') + 1];
  const year = match[parts.indexOf('Y') + 1];
  if (!day || !month || !year || year.length !== 4) return null;

  const iso = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
  const date = new Date(`${iso}T00:00:00`);
  if (Number.isNaN(date.getTime())) return null;

  // Round-tripped, because Date accepts the 31st of February and quietly
  // returns the 3rd of March.
  return date.getDate() === Number(day) && date.getMonth() + 1 === Number(month) ? iso : null;
}

export function toTyped(iso: string, order: string, separator: string): string {
  const match = ISO.exec((iso ?? '').trim());
  if (!match) return '';

  const [, year, month, day] = match;
  const parts: Record<string, string> = { D: day, M: month, Y: year };
  return order.split('').map((key) => parts[key]).join(separator);
}
