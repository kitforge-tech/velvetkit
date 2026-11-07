// Typed dates in the locale's order, and ISO dates for the form.
//
// The order ("DMY") and separator come from Ruby, which derives them from
// date.formats.typed in the locale, so one string governs what a date field
// accepts, shows and hints at.
const ISO = /^(\d{4})-(\d{2})-(\d{2})$/;
// Any of / - . or a space between the parts: people type what is in front of
// them, and being strict about the separator only creates work.
const PARTS = /^(\d{1,4})[/\-. ](\d{1,4})[/\-. ](\d{1,4})$/;
const SEPARATORS = /[/\-. ]/;
const LENGTH: Record<string, number> = { D: 2, M: 2, Y: 4 };

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

// What a date field holds as it's typed: digits only, in the locale's order,
// the separator put in as each part fills. A separator typed early ends the
// part, so "1/" becomes "01/". A pasted ISO date is turned round. `growing`
// is false while deleting, so backspacing over a separator isn't undone.
export function maskDate(raw: string, order: string, separator: string, growing = true): string {
  if (ISO.test(raw.trim())) return toTyped(raw.trim(), order, separator);

  const keys = order.split('');
  const parts: string[] = [];
  let current = '';
  for (const char of raw) {
    if (parts.length === keys.length) break;

    const key = keys[parts.length];
    if (/\d/.test(char)) {
      current += char;
      if (current.length === LENGTH[key]) {
        parts.push(current);
        current = '';
      }
    } else if (SEPARATORS.test(char) && current !== '' && key !== 'Y') {
      parts.push(current.padStart(LENGTH[key], '0'));
      current = '';
    }
  }

  let out = parts.join(separator);
  if (current) out += (parts.length ? separator : '') + current;
  else if (parts.length > 0 && parts.length < keys.length && (growing || SEPARATORS.test(raw.slice(-1)))) out += separator;
  return out;
}
