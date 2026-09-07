<div align="center">

# Pager Dots

A minimal virtual desktop switcher for the KDE Plasma panel.
A dot marks the current desktop, dimmed numbers show the rest.

<img width="256" height="32" alt="paperdots" src="https://github.com/user-attachments/assets/a8e3dd85-ebff-48bb-bd03-a839d810ba80" />

</div>

## Features

- Every virtual desktop shown as a label, with a dot for the current one
- Choice of label style: numbers, letters (A B C), roman numerals (I II III), Greek (α β γ), Cyrillic (а б в), Chinese (一 二 三), Heavenly Stems (甲 乙 丙), Hiragana (あ い う), Katakana (ア イ ウ), Hangul (ㄱ ㄴ ㄷ), Arabic-Indic digits (١ ٢ ٣), bars (▁ ▂ ▃), dots, fill up to current (● ● ○ ○), or blank
- Smooth dot animation between desktops, with a choice of style: stretch, fluid, float, glide, pulse, swing, wave, rail, bridge, blur, streak, zip, comet, footprints, glow, orbit, ripple, wake, lift, dive, roll, loop, elastic, slingshot, hop, jelly, spring, bounce, snap, drop, bubble, flip, ring, sparks, pop, fade, or none, and a speed slider
- Adjustable spacing between desktops
- Click a desktop to switch to it
- Scroll the mouse wheel over the widget to step through desktops (wraps around)
- Hover to see the desktop name in a tooltip
- Works in horizontal and vertical panels
- Follows your Plasma colour scheme and font

## Requirements

- KDE Plasma 6.2 or newer (the widget uses the QML D-Bus module introduced in 6.2)
- KWin as the window manager, on X11 or Wayland (desktops are switched through KWin's D-Bus interface)

## Installation

### KDE Store (recommended)

1. Right-click the panel or desktop and choose **Add Widgets…**
2. Click **Get New Widgets…** → **Download New Plasma Widgets**
3. Search for **Pager Dots** and click **Install**

### From a release archive

Download the `.plasmoid` file from the [releases page](https://github.com/Patruxs/pagerdots/releases), then run:

```sh
kpackagetool6 -t Plasma/Applet -i pat.pagerdots-1.1.0.plasmoid
```

### From source

```sh
git clone https://github.com/Patruxs/pagerdots.git
cd pagerdots
./build --install
```

To update later, run `git pull && ./build --install`.
To remove the widget, run `kpackagetool6 -t Plasma/Applet -r pat.pagerdots`.

## Usage

1. Right-click the panel and choose **Add Widgets…**
2. Search for **Pager Dots** and drag it onto the panel
3. Right-click the widget and choose **Configure Pager Dots…** to pick a label style, the dot animation and its speed; the preview at the top plays your choices live

## Development

The repository root is the plasmoid package itself (`metadata.json` plus `contents/`), so you can symlink it into place for live editing:

```sh
ln -s "$PWD" ~/.local/share/plasma/plasmoids/pat.pagerdots
```

Restart Plasma to reload the widget after changes:

```sh
systemctl --user restart plasma-plasmashell.service
```

Run `./build` to produce `dist/pat.pagerdots-<version>.plasmoid`, the file to upload to the [KDE Store](https://store.kde.org/).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/Patruxs/pagerdots/issues).

## License

This project is licensed under the GNU General Public License, version 2 or later. See [LICENSE](LICENSE).
