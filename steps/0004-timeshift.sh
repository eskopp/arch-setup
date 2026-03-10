#!/usr/bin/env bash
set -Eeuo pipefail

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

snapshot_exists() {
  local comment="$1"
  sudo timeshift --list 2>/dev/null | grep -Fq "$comment"
}

main() {
  local root_fstype root_subvol home_subvol root_uuid
  local initial_comment="initial btrfs snapshot with @home"

  root_fstype="$(findmnt -no FSTYPE /)"
  root_subvol="$(findmnt -no OPTIONS / | tr ',' '\n' | sed -n 's/^subvol=//p')"
  home_subvol="$(findmnt -no OPTIONS /home | tr ',' '\n' | sed -n 's/^subvol=//p')"
  root_uuid="$(findmnt -no UUID /)"

  [[ "$root_fstype" == "btrfs" ]] || die "/ is not on Btrfs"
  [[ "$root_subvol" == "@" || "$root_subvol" == "/@" ]] || die "Root subvolume is not @"
  [[ "$home_subvol" == "@home" || "$home_subvol" == "/@home" ]] || die "/home subvolume is not @home"

  msg "Installing Timeshift and required packages"
  sudo pacman -S --needed --noconfirm timeshift btrfs-progs cronie

  msg "Enabling cronie"
  sudo systemctl enable --now cronie.service

  msg "Writing Timeshift configuration"
  sudo install -d -m 755 /etc/timeshift

  sudo tee /etc/timeshift/timeshift.json >/dev/null <<JSON
{
  "backup_device_uuid" : "$root_uuid",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "true",
  "include_btrfs_home_for_restore" : "true",
  "stop_cron_emails" : "true",
  "btrfs_use_qgroup" : "true",
  "schedule_monthly" : "true",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "true",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "7",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [],
  "exclude-apps" : []
}
JSON

  if snapshot_exists "$initial_comment"; then
    msg "Initial Timeshift snapshot already exists, skipping creation"
  else
    msg "Creating initial Timeshift snapshot"
    sudo timeshift --btrfs --create --comments "$initial_comment" --tags O
  fi

  msg "Listing snapshots"
  sudo timeshift --list

  msg "0004 timeshift setup completed"
}

main "$@"
