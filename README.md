<div align="center">

# Pager Dots

A minimal virtual desktop switcher for the KDE Plasma panel.
A dot marks the current desktop, dimmed numbers show the rest.

![Pager Dots in a Plasma panel](assets/screenshot.png)

</div>

## Features

- Every virtual desktop shown as a number, with a dot for the current one
- Click a desktop to switch to it
- Scroll the mouse wheel over the widget to step through desktops (wraps around)
- Hover to see the desktop name in a tooltip
- Works in horizontal and vertical panels
- Follows your Plasma colour scheme and font, no configuration needed

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
kpackagetool6 -t Plasma/Applet -i pat.pagerdots-1.0.0.plasmoid
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
