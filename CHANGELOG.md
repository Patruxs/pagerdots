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
- Five more dot animations: fluid (a drop of liquid that stretches with speed and, being
  driven by a spring rather than a timer, keeps its momentum when you switch desktops in
  quick succession), bridge (spans both desktops for a moment, then draws in onto the new
  one), blur (a motion-blur smear while moving), drop (the old dot falls away while a new
  one drops in), and flip (turns over like a coin)
- Four more dot animations: slingshot (draws back from the new desktop, stretching like the
  band of a slingshot, then shoots over and settles), zip (streaks across as a fine line),
  snap (drawn in faster and faster, hits the new desktop with a squash and springs back to
  round), and sparks (bursts into sparks that fly across on their own arcs and gather into
  a new dot)
- Four more dot animations: float (drifts over on a soft spring and eases to a stop, keeping
  its momentum when you switch quickly), footprints (leaves a fading print on each desktop
  it passes), dive (sinks away, passes beneath the desktops and surfaces on the new one),
  and bubble (floats up and pops while a new dot bubbles up from below)

### Changed
- The gliding animations (stretch, glide, comet, ripple, glow, streak and elastic) now ease
  off the mark before decelerating, instead of jerking into motion at full speed
- The settings page is laid out in two columns, label styles beside the dot options, and
  the dot animations are picked from a two-column grid with a description of the chosen
  one underneath (and of any other on hover), rather than from a long single column
- Switching desktops while the dot is still on its way no longer stalls it: a move that cuts
  in on another sets off at speed instead of easing in again, so stepping quickly through
  desktops with the mouse wheel flows as one motion

### Fixed
- The cell width measured its labels through a property it was itself changing, so Plasma
  logged a binding-loop warning and re-laid the cells out on every desktop switch
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
