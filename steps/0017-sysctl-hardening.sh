#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=steps/_sudo.sh
source "$SCRIPT_DIR/_sudo.sh"

msg() {
  printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

main() {
  require_sudo_session

  local target="/etc/sysctl.d/99-local-hardening.conf"

  msg "Writing sysctl hardening config to ${target}"
  sudo install -d -m 0755 /etc/sysctl.d
  sudo tee "${target}" >/dev/null <<'SYSCTLEOF'
# Local workstation hardening baseline
# Intentionally conservative: no IPv6 disable, no blanket outgoing restrictions,
# no aggressive VM tuning, no user namespace breakage by default.

# Safer handling of symlinks / hardlinks / FIFOs / regular files
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2

# Userspace memory hardening
vm.mmap_min_addr = 65536
vm.mmap_rnd_bits = 32

# Kernel info leak reduction / attack surface reduction
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 3
kernel.kexec_load_disabled = 1
kernel.yama.ptrace_scope = 2
kernel.unprivileged_bpf_disabled = 1

# Harden JIT for BPF
net.core.bpf_jit_harden = 2

# No routing on a normal workstation
net.ipv4.ip_forward = 0
SYSCTLEOF

  msg "Applying sysctl settings"
  sudo sysctl --system

  msg "Showing resulting key values"
  sudo sysctl \
    fs.protected_hardlinks \
    fs.protected_symlinks \
    fs.protected_fifos \
    fs.protected_regular \
    vm.mmap_min_addr \
    vm.mmap_rnd_bits \
    kernel.kptr_restrict \
    kernel.dmesg_restrict \
    kernel.perf_event_paranoid \
    kernel.kexec_load_disabled \
    kernel.yama.ptrace_scope \
    kernel.unprivileged_bpf_disabled \
    net.core.bpf_jit_harden \
    net.ipv4.ip_forward

  msg "0017 sysctl hardening setup completed"
}

main "$@"
