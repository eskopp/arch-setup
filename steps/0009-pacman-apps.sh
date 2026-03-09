#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

main() {
  local packages=(
    7zip
    alacritty
    baobab
    brightnessctl
    btop
    chafa
    cliphist
    decibels
    epiphany
    fastfetch
    file-roller
    firefox
    foot
    fzf
    gimp
    gimp-help-de
    gimp-help-en
    gnome-calculator
    gnome-calendar
    gnome-clocks
    gnome-connections
    gnome-contacts
    gnome-disk-utility
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-system-monitor
    gnome-text-editor
    gnome-tweaks
    gnome-weather
    grim
    htop
    jq
    kitty
    krita
    loupe
    mako
    nano
    nautilus
    neovim
    openbsd-netcat
    pavucontrol
    playerctl
    rofi
    simple-scan
    slurp
    smartmontools
    snapshot
    swappy
    swayosd
    swww
    thunderbird
    tmux
    tree
    vim
    waybar
    wev
    wget
    wl-clipboard
    wofi
    xournalpp
    yazi
    zip
    zoxide
    zsh
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-syntax-highlighting
  )

  msg "Installing pacman applications from step 0009"
  sudo pacman -S --needed --noconfirm "${packages[@]}"

  msg "0009 pacman apps setup completed"
}

main "$@"
