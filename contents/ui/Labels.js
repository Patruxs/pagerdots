// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library

// Label styles offered in the settings page, in display order.
// `id` is what gets stored in the config; `preview` is shown in the picker.
const STYLES = [
    { id: "numbers",      name: "Numbers",             preview: "1 2 3 4" },
    { id: "letters",      name: "Letters",             preview: "A B C D" },
    { id: "lowerLetters", name: "Lowercase letters",   preview: "a b c d" },
    { id: "roman",        name: "Roman numerals",      preview: "I II III IV" },
    { id: "lowerRoman",   name: "Lowercase roman",     preview: "i ii iii iv" },
    { id: "greek",        name: "Greek letters",       preview: "α β γ δ" },
    { id: "cyrillic",     name: "Cyrillic letters",    preview: "а б в г" },
    { id: "chinese",      name: "Chinese numerals",    preview: "一 二 三 四" },
    { id: "stems",        name: "Heavenly Stems",      preview: "甲 乙 丙 丁" },
    { id: "hiragana",     name: "Hiragana",            preview: "あ い う え" },
    { id: "katakana",     name: "Katakana",            preview: "ア イ ウ エ" },
    { id: "hangul",       name: "Hangul",              preview: "ㄱ ㄴ ㄷ ㄹ" },
    { id: "arabicIndic",  name: "Arabic-Indic digits", preview: "١ ٢ ٣ ٤" },
    { id: "bars",         name: "Bars",                preview: "▁ ▂ ▃ ▄" },
    { id: "dots",         name: "Dots",                preview: "○ ○ ○ ○" },
    { id: "fill",         name: "Fill up to current",  preview: "● ● ○ ○" },
    { id: "pill",         name: "Pill",                preview: "" },   // drawn on the settings page
    { id: "blank",        name: "Blank",               preview: "" },
];

// Excel-style column letters: A..Z, AA, AB, ...
function letters(n) {
    let s = "";
    while (n > 0) {
        n--;
        s = String.fromCharCode(65 + (n % 26)) + s;
        n = Math.floor(n / 26);
    }
    return s;
}

function roman(n) {
    const table = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"],
                   [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
    let s = "";
    for (const [value, digits] of table) {
        while (n >= value) { s += digits; n -= value; }
    }
    return s;
}

// Pick the n-th glyph of an alphabet; past its end fall back to the plain number.
function fromAlphabet(alphabet, n) {
    return n >= 1 && n <= alphabet.length ? alphabet[n - 1] : String(n);
}
const GREEK    = "αβγδεζηθικλμνξοπρστυφχψω";
// Russian letters in the order used for numbered lists, which skips ё, й, ъ, ы and ь.
const CYRILLIC = "абвгдежзиклмнопрстуфхцчшщэюя";
// The ten Heavenly Stems, the traditional East Asian ordinal sequence.
const STEMS    = "甲乙丙丁戊己庚辛壬癸";
// Japanese kana in gojūon order.
const HIRAGANA = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん";
const KATAKANA = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン";
const HANGUL   = "ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ";
const BARS     = "▁▂▃▄▅▆▇█";

// Chinese numerals 一 .. 九十九; larger numbers fall back to digits.
function chinese(n) {
    const d = "零一二三四五六七八九";
    if (n < 1 || n > 99) return String(n);
    if (n < 10) return d[n];
    const tens = Math.floor(n / 10), ones = n % 10;
    return (tens > 1 ? d[tens] : "") + "十" + (ones ? d[ones] : "");
}

// Replace each ASCII digit with its Arabic-Indic equivalent (٠..٩).
function arabicIndic(n) {
    return String(n).replace(/\d/g, c => String.fromCharCode(0x0660 + Number(c)));
}

// The "pill" style draws the other desktops as dots the size of the marker, rather
// than as glyphs, and the marker rests among them as a pill, the way GNOME's page
// indicator does. Its proportions, taken from that: the dots are this fraction of the
// font height (the same as the usual marker), the pill is this many dots long, and
// each cell is this many dots wide, so that the dots sit one spacing apart. The row
// makes room for the pill, so it is one pill length wider than the dots alone. The
// style keeps GNOME's gap between the dots (PILL_GAP, in dots) in place of the spacing
// setting, unless the user has chosen to customise it (pillCustomSpacing).
const PILL_DOT = 0.45;
const PILL_LENGTH = 3.7;
const DOT_CELL = 1;
const PILL_GAP = 0.6;

// Whether the style shows the other desktops as drawn dots instead of a label.
function drawsDots(style) {
    return style === "pill";
}

// Whether the current desktop is marked by the dot (as opposed to its bold label).
// The "blank" style has no label to show, and the "pill" style is the dot resting as
// a pill, so both always use the dot.
function usesDot(style, dotForCurrent) {
    return dotForCurrent || style === "blank" || drawsDots(style);
}

// Label for the 1-based desktop number `n` in the given style. `current` is the
// 1-based number of the current desktop; only the "fill" style looks at it.
// An empty string means "show nothing" (the current desktop still gets the dot).
function labelFor(style, n, current) {
    switch (style) {
    case "letters":      return letters(n);
    case "lowerLetters": return letters(n).toLowerCase();
    case "roman":        return roman(n);
    case "lowerRoman":   return roman(n).toLowerCase();
    case "greek":        return fromAlphabet(GREEK, n);
    case "cyrillic":     return fromAlphabet(CYRILLIC, n);
    case "stems":        return fromAlphabet(STEMS, n);
    case "hiragana":     return fromAlphabet(HIRAGANA, n);
    case "katakana":     return fromAlphabet(KATAKANA, n);
    case "hangul":       return fromAlphabet(HANGUL, n);
    case "chinese":      return chinese(n);
    case "arabicIndic":  return arabicIndic(n);
    case "bars":         return n >= 1 ? BARS[Math.min(n, BARS.length) - 1] : String(n);
    case "dots":         return "○";
    case "fill":         return n <= current ? "●" : "○";
    case "blank":        return "";
    case "pill":         return "";
    default:             return String(n);
    }
}
