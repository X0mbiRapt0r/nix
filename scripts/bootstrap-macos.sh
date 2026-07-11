#!/usr/bin/env bash
set -euo pipefail

program_name="${0##*/}"
repo_url="${BOOTSTRAP_REPO_URL:-https://github.com/X0mbiRapt0r/nix.git}"
nix_install_url="https://nixos.org/nix/install"

usage() {
  cat <<USAGE
Usage:
  $program_name [HOST] [--repo PATH] [--pull|--no-pull] [--yes] [--print-command]
  $program_name --host HOST [--repo PATH] [--pull|--no-pull] [--yes] [--print-command]

Bootstrap a fresh macOS install into this nix-darwin flake.

Options:
  --host HOST       Darwin flake host to deploy. Prompts when omitted except
                    in print-only mode, which uses the detected host name.
  --repo PATH       Repo checkout to use. Defaults to the iCloud checkout when
                    present, then the repo this script is in, then the iCloud
                    checkout path as a clone target.
  --pull            Pull the existing git checkout before switching.
  --no-pull         Do not pull the existing checkout. This is the default.
  -y, --yes         Skip confirmation prompts where safe.
  --print-command   Print the first-switch command without running it.
  -h, --help        Show this help.

Homebrew is not installed with the Homebrew shell installer. This flake uses
nix-homebrew, so Homebrew is installed during the nix-darwin activation.
USAGE
}

log() {
  printf '>>> %s\n' "$*"
}

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

quote_command() {
  printf '%q' "$1"
  shift

  while [[ $# -gt 0 ]]; do
    printf ' %q' "$1"
    shift
  done
  printf '\n'
}

default_macos_repo_dir() {
  printf '%s\n' "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix"
}

find_default_repo_dir() {
  local script_dir
  local candidate
  local canonical

  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  candidate="$(cd "$script_dir/.." && pwd -P)"
  canonical="$(default_macos_repo_dir)"

  if [[ -f "$canonical/flake.nix" ]]; then
    printf '%s\n' "$canonical"
  elif [[ -f "$candidate/flake.nix" ]]; then
    printf '%s\n' "$candidate"
  else
    printf '%s\n' "$canonical"
  fi
}

canonicalize_checkout_path() {
  local path="$1"
  local parent

  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
    return
  fi

  parent="$(dirname "$path")"
  if [[ -d "$parent" ]]; then
    printf '%s/%s\n' "$(cd "$parent" && pwd -P)" "$(basename "$path")"
  else
    printf '%s\n' "$path"
  fi
}

confirm() {
  local prompt="$1"
  local answer

  if [[ "$assume_yes" == true ]]; then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    return 1
  fi

  printf '%s [y/N] ' "$prompt"
  read -r answer

  case "$answer" in
    y | Y | yes | YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

load_nix_profile() {
  local profile

  for profile in \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
    "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    if [[ -r "$profile" ]]; then
      # shellcheck disable=SC1090
      . "$profile"
      command -v nix >/dev/null 2>&1 && return 0
    fi
  done

  return 1
}

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    log "Nix already installed: $(nix --version)"
    return
  fi

  if load_nix_profile; then
    log "Nix already installed: $(nix --version)"
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install Nix."

  log "Nix not found. Installing the macOS multi-user Nix daemon."
  log "The installer may ask for sudo and confirmation."
  curl --proto '=https' --tlsv1.2 -L "$nix_install_url" | NIX_INSTALLER_NO_MODIFY_PROFILE=1 sh -s -- --daemon

  load_nix_profile || true
  command -v nix >/dev/null 2>&1 || die "Nix installed, but this shell cannot find nix yet. Open a new terminal and rerun $program_name."

  log "Installed Nix: $(nix --version)"
}

nix_command() {
  "$nix_bin" --extra-experimental-features "nix-command flakes" --accept-flake-config "$@"
}

git_command() {
  local git_bin

  git_bin="$(command -v git || true)"
  if [[ -n "$git_bin" ]] && { [[ "$git_bin" != "/usr/bin/git" ]] || xcode-select -p >/dev/null 2>&1; }; then
    "$git_bin" "$@"
  else
    # A fresh Mac exposes /usr/bin/git before Command Line Tools are installed;
    # use Nix's Git instead of triggering or depending on Apple's installer.
    nix_command shell nixpkgs#git -c git "$@"
  fi
}

ensure_repo() {
  local status

  if [[ -f "$repo_dir/flake.nix" ]]; then
    log "Using flake repo: $repo_dir"

    if [[ "$pull_repo" == true ]]; then
      [[ -d "$repo_dir/.git" ]] || die "--pull was requested, but $repo_dir is not a git checkout."
      status="$(git_command -C "$repo_dir" status --porcelain=v1)"
      if [[ -n "$status" ]]; then
        printf '%s\n' "$status" >&2
        die "Refusing to pull a checkout with uncommitted changes."
      fi
      log "Pulling latest changes with git pull --ff-only."
      git_command -C "$repo_dir" pull --ff-only
    fi

    return
  fi

  if [[ -e "$repo_dir" ]]; then
    die "$repo_dir exists, but it does not contain flake.nix."
  fi

  log "Repo not found. Cloning $repo_url into $repo_dir."
  mkdir -p "$(dirname "$repo_dir")"
  git_command clone "$repo_url" "$repo_dir"
}

list_darwin_hosts() {
  nix_command eval --raw "$repo_dir#darwinConfigurations" \
    --apply 'configs: builtins.concatStringsSep "\n" (builtins.attrNames configs)'
}

host_is_available() {
  local candidate="$1"
  printf '%s\n' "$darwin_hosts" | grep -Fx -- "$candidate" >/dev/null
}

print_available_hosts() {
  local available_host

  printf 'Available Darwin hosts:\n'
  while IFS= read -r available_host; do
    [[ -n "$available_host" ]] && printf '  - %s\n' "$available_host"
  done <<< "$darwin_hosts"
}

detect_macos_host() {
  if command -v scutil >/dev/null 2>&1; then
    scutil --get LocalHostName 2>/dev/null && return 0
  fi

  hostname -s 2>/dev/null || true
}

choose_host() {
  local detected_host
  local default_host
  local first_host
  local answer

  darwin_hosts="$(list_darwin_hosts)"
  [[ -n "$darwin_hosts" ]] || die "No darwinConfigurations are defined in $repo_dir/flake.nix."

  if [[ -n "$host" ]]; then
    if ! host_is_available "$host"; then
      print_available_hosts >&2
      die "Host '$host' is not defined under darwinConfigurations."
    fi
    return
  fi

  [[ -t 0 ]] || die "No host supplied and stdin is not interactive. Re-run with --host HOST."

  detected_host="$(detect_macos_host)"
  first_host="$(printf '%s\n' "$darwin_hosts" | sed -n '1p')"

  if [[ -n "$detected_host" ]] && host_is_available "$detected_host"; then
    default_host="$detected_host"
  else
    default_host="$first_host"
  fi

  print_available_hosts

  while true; do
    printf 'Host to deploy [%s]: ' "$default_host"
    read -r answer
    host="${answer:-$default_host}"

    if host_is_available "$host"; then
      return
    fi

    warn "Host '$host' is not defined under darwinConfigurations."
  done
}

configured_host_system() {
  nix_command eval --raw "$repo_dir#darwinConfigurations.$host.pkgs.stdenv.hostPlatform.system"
}

current_darwin_system() {
  case "$(uname -m)" in
    arm64)
      printf 'aarch64-darwin\n'
      ;;
    x86_64)
      printf 'x86_64-darwin\n'
      ;;
    *)
      printf 'unknown-darwin\n'
      ;;
  esac
}

validate_host_system() {
  local configured_system
  local current_system

  configured_system="$(configured_host_system)"
  current_system="$(current_darwin_system)"

  log "Selected host: $host ($configured_system)"

  if [[ "$current_system" == unknown-darwin || "$configured_system" == "$current_system" ]]; then
    return
  fi

  warn "This Mac is $current_system, but $host is configured for $configured_system."
  if ! confirm "Continue anyway?"; then
    die "Aborted before switching."
  fi
}

build_switch_command() {
  flake_ref="$repo_dir#$host"
  switch_cmd=(
    sudo -H "$nix_bin"
    --extra-experimental-features "nix-command flakes"
    --accept-flake-config
    run "github:nix-darwin/nix-darwin/master#darwin-rebuild"
    --
    switch
    --flake "$flake_ref"
    -L
  )
}

print_switch_command() {
  printf 'First-switch command:\n  '
  quote_command "${switch_cmd[@]}"
}

backup_for_nix_darwin() {
  local path="$1"
  local target
  local backup

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    return
  fi

  if [[ -L "$path" ]]; then
    target="$(readlink "$path" || true)"
    if [[ "$target" == /nix/store/* ]]; then
      log "$path is already managed by Nix."
      return
    fi
  fi

  backup="$path.before-nix-darwin"
  if [[ -e "$backup" || -L "$backup" ]]; then
    backup="$path.before-nix-darwin.$(date +%Y%m%d%H%M%S)"
  fi

  log "Backing up $path to $backup."
  sudo mv "$path" "$backup"
}

prepare_for_nix_darwin() {
  log "Preparing system files that nix-darwin will manage."
  backup_for_nix_darwin /etc/zshrc
  backup_for_nix_darwin /etc/bashrc
  backup_for_nix_darwin /etc/nix/nix.conf
}

host=""
repo_dir=""
canonical_repo_dir=""
pull_repo=false
assume_yes=false
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
    --no-pull)
      pull_repo=false
      shift
      ;;
    -y | --yes)
      assume_yes=true
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
      if [[ "$1" == -* ]]; then
        die "Unknown option: $1"
      fi

      if [[ -z "$host" ]]; then
        host="$1"
        shift
      else
        die "Unexpected argument: $1"
      fi
      ;;
  esac
done

[[ "$(uname -s)" == "Darwin" ]] || die "$program_name is for macOS only."
[[ "$(id -u)" -ne 0 ]] || die "Run this as your normal user. The script uses sudo when needed."

canonical_repo_dir="$(canonicalize_checkout_path "$(default_macos_repo_dir)")"
repo_dir="$(canonicalize_checkout_path "${repo_dir:-$(find_default_repo_dir)}")"

log "Bootstrap repo: $repo_dir"
if [[ "$repo_dir" != "$canonical_repo_dir" ]]; then
  warn "Helper commands default to the standard checkout at $canonical_repo_dir."
  warn "Pass --repo PATH when running a helper against this checkout."
fi

if [[ "$print_command" == true ]]; then
  if [[ -z "$host" ]]; then
    host="$(detect_macos_host)"
    [[ -n "$host" ]] || die "Could not detect a host name. Re-run with --host HOST."
  fi

  nix_bin="$(command -v nix || true)"
  nix_bin="${nix_bin:-nix}"
  build_switch_command
  print_switch_command
  log "Print-only mode did not install Nix, clone or pull the repo, validate the host, back up files, or activate nix-darwin."
  exit 0
fi

ensure_nix
nix_bin="$(command -v nix)"

ensure_repo
choose_host
validate_host_system

build_switch_command
print_switch_command

prepare_for_nix_darwin

log "Activating nix-darwin. Homebrew will be installed by nix-homebrew during this switch."
"${switch_cmd[@]}"

cat <<EOF

Bootstrap complete.

Next normal switch:
  nix-switch $host

If this was a first-time shell, open a new terminal so zsh, PATH, and Home Manager
session settings are loaded from the activated configuration.
EOF
