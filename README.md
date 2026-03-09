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

## Repository structure

~~~text
arch-setup/
├── bootstrap.sh
├── install.sh
├── .gitignore
├── .gitattributes
├── LICENSE
├── README.md
└── steps/
    ├── 0001-base.sh
    ├── 0002-packages.sh
    ├── 0003-services.sh
    └── 0004-timeshift.sh
~~~

## Notes

- Run the scripts as a normal user, not as root.
- `bootstrap.sh` expects `install.sh` in the repository root.
- The scripts are intended for personal Arch Linux setup automation.

## License

See `LICENSE` in the repository root.
