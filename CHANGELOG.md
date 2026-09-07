# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- More label styles: Cyrillic letters (а б в), Heavenly Stems (甲 乙 丙), Hiragana (あ い う),
  Katakana (ア イ ウ), and "fill up to current", which fills the circles of every desktop up to
  the current one (● ● ○ ○) so the row reads like a progress bar
- Five more dot animations: lift (picked up, carried over and set down), roll (rolls along
  the row like a ball), elastic (tethered to the old desktop by a band that stretches and
  snaps back), streak (a light trail that fades behind the dot), and glow (a soft halo
  that blooms as the dot sets off and fades as it lands)
- Animation speed slider in the settings, from half to double speed

### Changed
- The label under the dot now fades back in only once the dot has actually left it, and
  ducks quickly under the dot as it arrives, so the two no longer overlap mid-move
- Dot shapes are drawn antialiased, for smoother edges while moving

## [1.1.0] - 2026-09-07

### Added
- Settings page (right-click → Configure Pager Dots…) with a choice of desktop label styles:
  numbers, letters (A B C), lowercase letters, roman numerals (I II III), lowercase roman
  numerals, Greek letters (α β γ), Chinese numerals (一 二 三), Hangul (ㄱ ㄴ ㄷ),
  Arabic-Indic digits (١ ٢ ٣), bars (▁ ▂ ▃), dots, or blank
- Option to show the current desktop as its own label (bold) instead of a dot
- The dot now animates to the new desktop instead of jumping, and the label underneath
  cross-fades. Eleven animations to choose from in the settings: stretch (the dot
  elongates into a pill towards the new desktop, then snaps back), glide, comet (fading
  trail), ripple (a ring spreads out where it lands), hop (arc jump with a landing
  squash), jelly (squash and stretch with a wobble), spring, bounce, pop, fade, or none
- Live preview in the settings page showing the chosen label style and animation

## [1.0.0] - 2026-09-07

Initial release.

### Added
- A dot for the current virtual desktop, dimmed numbers for the others
- Click a desktop to switch to it
- Mouse wheel over the widget steps through desktops, wrapping around
- Tooltip showing the desktop name
- Horizontal and vertical panel layouts

[Unreleased]: https://github.com/Patruxs/pagerdots/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Patruxs/pagerdots/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Patruxs/pagerdots/releases/tag/v1.0.0
