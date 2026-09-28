// SPDX-FileCopyrightText: 2026 Thuan Phat <laithuanphat@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library


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
    { id: "pill",         name: "Pill",                preview: "" },   
    { id: "blank",        name: "Blank",               preview: "" },
];


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


function fromAlphabet(alphabet, n) {
    return n >= 1 && n <= alphabet.length ? alphabet[n - 1] : String(n);
}
const GREEK    = "αβγδεζηθικλμνξοπρστυφχψω";
const CYRILLIC = "абвгдежзиклмнопрстуфхцчшщэюя";
const STEMS    = "甲乙丙丁戊己庚辛壬癸";
const HIRAGANA = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん";
const KATAKANA = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン";
const HANGUL   = "ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ";
const BARS     = "▁▂▃▄▅▆▇█";

function chinese(n) {
    const d = "零一二三四五六七八九";
    if (n < 1 || n > 99) return String(n);
    if (n < 10) return d[n];
    const tens = Math.floor(n / 10), ones = n % 10;
    return (tens > 1 ? d[tens] : "") + "十" + (ones ? d[ones] : "");
}

function arabicIndic(n) {
    return String(n).replace(/\d/g, c => String.fromCharCode(0x0660 + Number(c)));
}


const PILL_DOT = 0.45;
const PILL_LENGTH = 3.7;
const DOT_CELL = 1;
const PILL_GAP = 0.6;

function drawsDots(style) {
    return style === "pill";
}


function usesDot(style, dotForCurrent) {
    return dotForCurrent || style === "blank" || drawsDots(style);
}

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
