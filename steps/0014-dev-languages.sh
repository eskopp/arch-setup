#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

# Install development languages and writing tools on Arch Linux:
# - Go
# - Rust
# - C/C++ (gcc / g++)
# - Python + pip
# - Hugo
# - R
# - Julia
# - Zig
# - TeX Live + TeXstudio + Typst
#
# Also create A4 starter templates for LaTeX and Typst.

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  echo "Cannot read /etc/os-release"
  exit 1
fi

if [[ "${ID:-}" != "arch" ]]; then
  echo "This script only supports Arch Linux."
  exit 1
fi

if ! command -v sudo > /dev/null 2>&1; then
  echo "sudo is required but not installed."
  exit 1
fi

require_sudo_session

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"

if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  echo "Could not determine home directory for user '${TARGET_USER}'."
  exit 1
fi

run_for_target() {
  if [[ "$(id -un)" == "${TARGET_USER}" ]]; then
    "$@"
  else
    sudo -u "${TARGET_USER}" "$@"
  fi
}

PACKAGES=(
  gcc
  make
  go
  rustup
  python
  python-pip
  hugo
  r
  julia
  zig
  texlive-meta
  texstudio
  typst
  okular
  biber
  hunspell
  hunspell-de
  hunspell-en_us
  fzf
)

echo "Installing development and writing packages..."
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"

if command -v rustup > /dev/null 2>&1; then
  echo "Ensuring Rust stable toolchain is initialized..."
  if ! run_for_target env HOME="${TARGET_HOME}" rustup show active-toolchain > /dev/null 2>&1; then
    run_for_target env HOME="${TARGET_HOME}" rustup default stable
  fi
fi

echo "Creating A4 starter templates..."
run_for_target mkdir -p "${TARGET_HOME}/Templates"

LATEX_TEMPLATE="${TARGET_HOME}/Templates/latex-a4.tex"
TYPST_TEMPLATE="${TARGET_HOME}/Templates/typst-a4.typ"

if [[ ! -f "${LATEX_TEMPLATE}" ]]; then
  cat > /tmp/latex-a4.tex << 'LATEXEOF'
\documentclass[a4paper,11pt]{article}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage[ngerman,english]{babel}
\usepackage[a4paper,margin=2.5cm]{geometry}
\usepackage{microtype}
\usepackage{hyperref}

\title{A4 LaTeX Template}
\author{Erik}
\date{\today}

\begin{document}
\maketitle

Hello world.

\end{document}
LATEXEOF
  install -m 644 /tmp/latex-a4.tex "${LATEX_TEMPLATE}"
  rm -f /tmp/latex-a4.tex
fi

if [[ ! -f "${TYPST_TEMPLATE}" ]]; then
  cat > /tmp/typst-a4.typ << 'TYPSTEOF'
#set page(
  paper: "a4",
  margin: 2.5cm,
)

#set text(
  lang: "de",
  size: 11pt,
)

= A4 Typst Template

Hello world.
TYPSTEOF
  install -m 644 /tmp/typst-a4.typ "${TYPST_TEMPLATE}"
  rm -f /tmp/typst-a4.typ
fi

if [[ "$(id -u)" -eq 0 ]]; then
  chown "${TARGET_USER}:${TARGET_USER}" "${LATEX_TEMPLATE}" "${TYPST_TEMPLATE}"
fi

echo
echo "Verification:"
g++ --version | sed -n '1p' || true
go version || true
rustc --version || true
cargo --version || true
python --version || true
pip --version || true
hugo version || true
R --version | sed -n '1p' || true
julia --version || true
zig version || true
typst --version || true
texstudio --version | sed -n '1p' || true
biber --version | sed -n '1p' || true

echo
echo "Done."
echo "A4 templates were placed in:"
echo "  ${LATEX_TEMPLATE}"
echo "  ${TYPST_TEMPLATE}"
