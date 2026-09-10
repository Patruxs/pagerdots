# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- A "Pill" label style: the desktops as small dots, with the current one a wide pill
  among them, in the proportions of GNOME's page indicator. The row makes room for the
  pill wherever it goes. The style comes with that indicator's animation too: the old
  pill shrinks back into a dot as a dot grows into the new pill, and that indicator's
  spacing. The animation options and the spacing are locked while it is in use; a
  "Customize animation…" button and a lock button beside the spacing unlock them, each
  after a warning. The other animations then stretch, squash and carry the pill just as
  they do the dot ("Fade" is the GNOME-style one). The speed slider stays available.
- A rounded background behind the desktops while the mouse is over the widget, as in
  GNOME, with every label style.
- A "Behavior" settings page, after the old one, now "Appearance". Mouse: whether the
  wheel switches desktops, whether it wraps around at the ends, whether it is inverted,
  and what a click on the current desktop does (nothing, show the desktop, the Overview
  or the desktop grid), from the current desktop alone or from anywhere on the widget.
  Tooltips: whether hovering shows the desktop's name, and whether it lists the windows
  on it. Desktop management: which of the new context menu entries to offer.
- Context menu entries to add a desktop, remove the last one, rename the current one
  (in a small popup by the widget) and open the Virtual Desktops settings. A base name
  for new desktops can be set; they are numbered after it ("Work 3").
- Optionally, desktops are added and removed on their own, GNOME-style: there is
  always exactly one empty desktop after the last one with windows, and empty desktops
  are removed once left.

### Fixed
- In a panel thinner than about 25 pixels the row sat a couple of pixels below the
  panel's centre: the cells asked for a minimum height the panel could not give, and
  the row overflowed it. They now take the panel's height.

## [1.2.1] - 2026-09-08

### Fixed
- The dot animations played differently in the panel and in the settings preview. Every
  slide ran on the same smooth curve in the panel, so zip, stretch, spring, hop, swing and
  elastic all looked alike there, and spring wobbled at a different rate in the two
  places. Setting the bezier curve on a Qt easing replaces its type, and changing the
  type resets the elastic period, so with separate bindings the result depended on
  whether the animation was chosen before or after the widget loaded. The easing is now
  built in one piece.
- Hops, arcs, drops, beams and bursts reached further across the row in a thick panel
  than in the preview; the room across the row is now capped at about the dot's size,
  which is what the preview's cells allow.

### Removed
- The zip animation: on a dot a few pixels across it read as stretch, only thinner. A
  saved "zip" setting falls back to stretch.

## [1.2.0] - 2026-09-08

### Added
- More label styles: Cyrillic letters (а б в), Heavenly Stems (甲 乙 丙), Hiragana (あ い う),
  Katakana (ア イ ウ), and "fill up to current", which fills the circles of every desktop up to
  the current one (● ● ○ ○) so the row reads like a progress bar
- Three more dot animations: lift (picked up, carried over and set down), elastic
  (tethered to the old desktop by a band that stretches and snaps back), and glow (a soft
  halo that blooms as the dot sets off and fades as it lands)
- Animation speed slider in the settings, from half to double speed
- Drop dot animation: the old dot falls away while a new one drops in
- Two more dot animations: zip (streaks across as a fine line), and sparks (bursts into
  sparks that fly across on their own arcs and gather into a new dot)
- Footprints dot animation: leaves a fading print on each desktop it passes
- Two more dot animations: swing (swings over in a smooth arc, like a pendulum), and ring
  (the dot opens out into a ring that fades from the old desktop, while a ring closes in
  and fills to a dot on the new one)
- Pour dot animation: drains from the old desktop into the new one down a thin stream,
  shrinking on one as it grows on the other
- Option to draw the dot in the colour scheme's accent colour instead of the text colour
- Six more dot animations, each with a shape of its own: beam (stretches into a tall thin
  beam that fades from the old desktop, while a beam appears on the new one and collapses
  into a dot), split (divides into two half dots that swing out to either side, cross over
  and merge again), flash (appears on the new desktop at once and blinks twice), wrap
  (leaves past the end of the row and comes back in from the other end), steps (jumps over
  in a few discrete stops, stop-motion style), and boomerang (draws back a whole desktop
  away, then flies across and lands)
- Four more dot animations: topple (stands up into a post that topples over like a domino
  onto the new desktop), cartwheel (flattens into a short bar that turns end over end as
  it crosses), arrow (sharpens into an arrowhead that shoots over and rounds off into a
  dot again), and train (breaks into a file of three beads that run across in line and
  merge again)
- Four more dot animations: twinkle (collapses into a spinning four-point star that
  shrinks away, while a star flares up on the new desktop and rounds off into a dot), hoop
  (opens out into a hollow hoop, larger than itself, that rolls across and closes back into
  a dot), billiards (slides across at a steady pace and stops dead on the new desktop,
  knocking a second dot out ahead of it that flies on and fades), and recoil (pops up on
  the new desktop at once, kicking the old dot back the other way, where it fades)
- Four more dot animations: loop (loops the loop on the way over, forward and up over the
  top, back underneath, and on to the new desktop), volley (flies over, is batted straight
  back to the old desktop, and flies over again to stay), flip (slides across while
  flipping over like a coin, thinning to a sliver edge on and back), and burst (bursts into
  pieces that fly out all round and fade on the old desktop, while pieces fly in from all
  round the new one and gather into a dot)

### Changed
- The gliding animations (stretch, glide, ripple, glow and elastic) now ease
  off the mark before decelerating, instead of jerking into motion at full speed
- The settings page is laid out in two columns, label styles beside the dot options, and
  the dot animations are picked from a two-column grid with a description of the chosen
  one underneath (and of any other on hover), rather than from a long single column
- Switching desktops while the dot is still on its way no longer stalls it: a move that cuts
  in on another sets off at speed instead of easing in again, so stepping quickly through
  desktops with the mouse wheel flows as one motion
- Each dot animation now lives in its own file under `contents/ui/animations/`, on a shared
  base that documents the hooks it can drive, and `tests/run` checks every one of them
  without a Plasma session; the README explains how to add one

### Removed
- The comet, jelly and bounce dot animations: at the size of a panel dot, comet and jelly
  looked the same as stretch, and bounce the same as spring. A saved choice of one of them
  now plays as glide

### Fixed
- Scrolling over the widget with a touchpad, or a free-spinning wheel, stepped a desktop for
  every tiny scroll event, so one swipe skipped through several desktops; the scroll is now
  added up and steps one desktop per full wheel notch
- The settings page no longer logs a warning for each option's default value when it opens
- The cell width measured its labels through a property it was itself changing, so Plasma
  logged a binding-loop warning and re-laid the cells out on every desktop switch
- The label under the dot now fades back in only once the dot has actually left it, and
  ducks quickly under the dot as it arrives, so the two no longer overlap mid-move
- Dot shapes are drawn antialiased, for smoother edges while moving
- The topple and arrow animations briefly showed a stray dot in the wrong place as they set
  off (wherever the last swap had left its copy of the dot); the old dot now shrinks away on
  the desktop it leaves

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
- Adjustable space between desktops, so wide labels such as roman numerals do not crowd each other

## [1.0.0] - 2026-09-07

Initial release.

### Added
- A dot for the current virtual desktop, dimmed numbers for the others
- Click a desktop to switch to it
- Mouse wheel over the widget steps through desktops, wrapping around
- Tooltip showing the desktop name
- Horizontal and vertical panel layouts

[Unreleased]: https://github.com/Patruxs/pagerdots/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/Patruxs/pagerdots/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/Patruxs/pagerdots/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Patruxs/pagerdots/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Patruxs/pagerdots/releases/tag/v1.0.0
