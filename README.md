# arch-setup

Scripts for setting up an Arch Linux system.

## Overview

This repository contains personal setup scripts for Arch Linux.

The goal is to provide a simple and reusable way to bootstrap a fresh Arch system and run a local `install.sh` script from this repository.

## Requirements

- Arch Linux
- `sudo`
- `bash`
- internet access

`git` will be installed automatically by `bootstrap.sh` if it is missing.

## Installation

### Option 1: Bootstrap with curl

~~~bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/eskopp/arch-setup/main/bootstrap.sh)"
~~~

This will:

1. check that the system is Arch Linux
2. request `sudo`
3. install `git` if needed
4. clone or update this repository
5. run `install.sh`

### Option 2: Clone manually

~~~bash
git clone https://github.com/eskopp/arch-setup.git
cd arch-setup
bash install.sh
~~~

## Running specific steps

Run only selected steps:

~~~bash
bash install.sh 0000-preflight 0001-base 0002-hyprland-base 0019-hyprland
~~~

Skip specific steps while running the default full flow:

~~~bash
SKIP_STEPS="0010-docker 0014-dev-languages" bash install.sh
~~~

## Logging and summary

Each installer run writes a log file under:

~~~text
~/.local/state/arch-setup/logs/
~~~

At the end of the run, the installer prints a summary with:

- overall status
- log file path
- ran steps
- skipped steps
- failed steps

## Repository structure

~~~text
arch-setup/
├── bootstrap.sh
├── install.sh
├── .gitignore
├── .gitattributes
├── LICENSE
├── README.md
├── .github/
│   └── workflows/
│       └── gitlab.yml
└── steps/
    ├── 0000-preflight.sh
    ├── 0001-base.sh
    ├── 0002-hyprland-base.sh
    ├── 0004-timeshift.sh
    ├── 0005-peripherals.sh
    ├── 0006-cloud-and-repos.sh
    ├── 0007-pacman-initramfs-hook.sh
    ├── 0008-aur-helpers.sh
    ├── 0009-cli-apps.sh
    ├── 0010-docker.sh
    ├── 0011-mullvad.sh
    ├── 0012-alacritty.sh
    ├── 0013-desktop-apps.sh
    ├── 0014-dev-languages.sh
    ├── 0015-communication-apps.sh
    ├── 0016-random-wallpaper.sh
    ├── 0017-creative-tools.sh
    ├── 0018-wayland-extras.sh
    ├── 0019-hyprland.sh
    ├── 0090-remove-gnome-and-niri.sh
    ├── 0091-tty-login.sh
    ├── 098-dotfiles.sh
~~~

## Notes

- Run the scripts as a normal user, not as root.
- `bootstrap.sh` expects `install.sh` in the repository root.
- The scripts are intended for personal Arch Linux setup automation.
- `0090-remove-gnome-and-niri.sh` and `0091-tty-login.sh` are intentionally destructive and print warnings before they run.

## License

See `LICENSE` in the repository root.
