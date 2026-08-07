#!/usr/bin/env bash
set -euo pipefail

program_name="${0##*/}"
repo_url="https://github.com/X0mbiRapt0r/nix.git"
nix_install_url="https://nixos.org/nix/install"

usage() {
  cat <<USAGE
Usage:
  $program_name [--host HOST] [--repo PATH] [--pull] [--print-command]

Bootstrap a clean Mac into this nix-darwin flake.

Options:
  --host HOST       Darwin flake host to deploy. Defaults to the Mac's local
                    hostname; pass this explicitly when setting up a new host.
  --repo PATH       Existing checkout or clone destination. From a checkout,
                    that checkout is used; otherwise the standard iCloud path.
  --pull            Fast-forward an existing clean checkout before activation.
  --print-command   Print the plan without changing the machine.
  -h, --help        Show this help.

The script installs Nix when needed. Homebrew is installed declaratively by
nix-homebrew during the first nix-darwin activation.
USAGE
}

log() {
  printf '>>> %s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

quote_command() {
  printf ' %q' "$@"
  printf '\n'
}

detect_host() {
  scutil --get LocalHostName 2>/dev/null || hostname -s 2>/dev/null || true
}

default_repo_dir() {
  local script_dir

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || true)"
  if [[ -n "$script_dir" && -f "$script_dir/../flake.nix" ]]; then
    (cd "$script_dir/.." && pwd -P)
  else
    printf '%s\n' "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix"
  fi
}

load_nix() {
  if command -v nix >/dev/null 2>&1; then
    return 0
  fi

  if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  command -v nix >/dev/null 2>&1
}

ensure_nix() {
  if load_nix; then
    log "Using $(nix --version)."
    return
  fi

  log "Installing the macOS multi-user Nix daemon."
  curl --fail --show-error --location --proto '=https' --tlsv1.2 "$nix_install_url" |
    NIX_INSTALLER_NO_MODIFY_PROFILE=1 sh -s -- --daemon

  load_nix || die "Nix was installed, but this shell cannot find it. Open a new terminal and rerun $program_name."
}

nix_command() {
  "$nix_bin" --extra-experimental-features "nix-command flakes" "$@"
}

git_command() {
  local git_bin

  git_bin="$(command -v git || true)"
  if [[ -n "$git_bin" ]] && { [[ "$git_bin" != /usr/bin/git ]] || xcode-select -p >/dev/null 2>&1; }; then
    "$git_bin" "$@"
  else
    # Avoid requiring Command Line Tools just to clone the configuration.
    nix_command shell nixpkgs#git -c git "$@"
  fi
}

ensure_repo() {
  local status

  if [[ -f "$repo_dir/flake.nix" ]]; then
    log "Using flake repo: $repo_dir"

    if [[ "$pull_repo" == true ]]; then
      [[ -d "$repo_dir/.git" ]] || die "--pull requires a Git checkout: $repo_dir"
      status="$(git_command -C "$repo_dir" status --porcelain=v1)"
      [[ -z "$status" ]] || die "Refusing to pull a checkout with uncommitted changes."
      git_command -C "$repo_dir" pull --ff-only
    fi
    return
  fi

  [[ ! -e "$repo_dir" ]] || die "$repo_dir exists but does not contain flake.nix."
  log "Cloning $repo_url into $repo_dir."
  mkdir -p "$(dirname "$repo_dir")"
  git_command clone "$repo_url" "$repo_dir"
}

current_system() {
  case "$(uname -m)" in
    arm64) printf 'aarch64-darwin\n' ;;
    x86_64) printf 'x86_64-darwin\n' ;;
    *) die "Unsupported Mac architecture: $(uname -m)" ;;
  esac
}

validate_host() {
  local configured_system
  local machine_system

  if ! configured_system="$(
    nix_command eval --raw "$repo_dir#darwinConfigurations.$host.pkgs.stdenv.hostPlatform.system"
  )"; then
    die "Host '$host' is not a valid Darwin configuration in $repo_dir."
  fi

  machine_system="$(current_system)"
  [[ "$configured_system" == "$machine_system" ]] ||
    die "Host '$host' targets $configured_system, but this Mac is $machine_system."

  log "Selected host: $host ($configured_system)"
}

backup_system_file() {
  local path="$1"
  local target
  local backup

  [[ -e "$path" || -L "$path" ]] || return

  if [[ -L "$path" ]]; then
    target="$(readlink "$path" || true)"
    [[ "$target" == /nix/store/* ]] && return
  fi

  backup="$path.before-nix-darwin"
  [[ ! -e "$backup" && ! -L "$backup" ]] || backup="$backup.$(date +%Y%m%d%H%M%S)"
  log "Backing up $path to $backup."
  sudo mv "$path" "$backup"
}

build_switch_command() {
  switch_command=(
    sudo -H "$nix_bin"
    --extra-experimental-features "nix-command flakes"
    run "github:nix-darwin/nix-darwin/master#darwin-rebuild"
    --
    switch
    --flake "$repo_dir#$host"
    -L
  )
}

print_plan() {
  printf 'Host: %s\nRepo: %s\n' "$host" "$repo_dir"

  if load_nix; then
    printf 'Nix: already installed\n'
    nix_bin="$(command -v nix)"
  else
    printf 'Install Nix:\n'
    printf "  curl --fail --show-error --location --proto '=https' --tlsv1.2 %q | sh -s -- --daemon\n" "$nix_install_url"
    nix_bin="nix"
  fi

  if [[ -f "$repo_dir/flake.nix" ]]; then
    printf 'Checkout: reuse%s\n' "$(if [[ "$pull_repo" == true ]]; then printf ' and fast-forward'; fi)"
  else
    printf 'Clone:'
    quote_command git clone "$repo_url" "$repo_dir"
  fi

  printf 'Back up unmanaged: /etc/zshrc /etc/bashrc /etc/nix/nix.conf\n'
  build_switch_command
  printf 'First switch:'
  quote_command "${switch_command[@]}"
}

host=""
repo_dir=""
pull_repo=false
print_command=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host="${2:?Missing value for --host}"
      shift 2
      ;;
    --repo)
      repo_dir="${2:?Missing value for --repo}"
      shift 2
      ;;
    --pull)
      pull_repo=true
      shift
      ;;
    --print-command)
      print_command=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ "$(uname -s)" == Darwin ]] || die "$program_name is for macOS only."
[[ "$(id -u)" -ne 0 ]] || die "Run this as your normal user; sudo is used only when required."

host="${host:-$(detect_host)}"
[[ -n "$host" ]] || die "Could not detect a hostname; rerun with --host HOST."
repo_dir="${repo_dir:-$(default_repo_dir)}"

if [[ "$print_command" == true ]]; then
  print_plan
  exit 0
fi

ensure_nix
nix_bin="$(command -v nix)"
ensure_repo
validate_host
build_switch_command

printf 'First switch:'
quote_command "${switch_command[@]}"

backup_system_file /etc/zshrc
backup_system_file /etc/bashrc
backup_system_file /etc/nix/nix.conf

log "Activating nix-darwin; nix-homebrew will install Homebrew and declared applications."
"${switch_command[@]}"

printf '\nBootstrap complete. Open a new terminal, then use nrs for normal switches.\n'
