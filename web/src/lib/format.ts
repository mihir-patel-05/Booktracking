const NUMERALS: Array<[number, string]> = [
  [1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
  [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"],
];

/** Levels and stages are set as numerals, in the manner of a title page. */
export function roman(value: number) {
  let left = Math.max(0, Math.floor(value));
  if (left === 0) return "—";
  let out = "";
  for (const [amount, numeral] of NUMERALS) {
    while (left >= amount) {
      out += numeral;
      left -= amount;
    }
  }
  return out;
}

export function percentRead(currentPage: number, totalPages: number) {
  if (!totalPages || totalPages <= 0) return 0;
  return Math.max(0, Math.min(100, Math.round((currentPage / totalPages) * 100)));
}
