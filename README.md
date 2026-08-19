# Unified Nix configuration

This flake manages a small set of NixOS and Apple Silicon macOS hosts with
shared Nix, Home Manager, and shell configuration. macOS applications are
declared through nix-darwin and nix-homebrew; NixOS host policy stays with the
host that needs it.

## Hosts

- `Irish-MBP`: an Apple Silicon macOS system managed by nix-darwin.
- `Irish-MBP-2013`: a 2013 Intel MacBook Pro running NixOS with COSMIC and Steam.
- `Irish-PC`: an x86_64 NixOS gaming system.
- `QTM-Irish-MBA`: an Apple Silicon work Mac managed by nix-darwin.
- `QTM-Irish-NUC`: a headless x86_64 NixOS automation host.

## Layout

- `flake.nix` declares inputs, hosts, formatters, and validation checks.
- `modules/` contains shared system and macOS configuration.
- `home/irish/` contains shared and platform-specific Home Manager modules.
- `hosts/` contains the policy and hardware configuration unique to each host.
- `scripts/` contains explicit bootstrap, update, switch, and cleanup helpers.

## Helper commands

Home Manager exposes these scripts in `~/.local/bin`:

- `nix-switch` builds and activates the selected host. On NixOS, it first
  fast-forwards a clean checkout by default; use `--no-pull` to skip that step.
- `nfu` fast-forwards the current branch, updates `flake.lock`, validates it,
  commits the lock-file change, and pushes. It requires a clean publishing
  checkout; use `--no-push` to keep the commit local.
- `ngc` trims old generations across known user and system profiles, then runs
  store garbage collection. It keeps two generations by default and may use
  `sudo` for system-owned profiles.

Each helper supports `--help` and `--print-command` for its exact options and
planned side effects.

## Bootstrapping macOS

On a clean Mac, run the bootstrap directly from this repository and name the
Darwin host to deploy:

```sh
curl --fail --show-error --location \
  https://raw.githubusercontent.com/X0mbiRapt0r/nix/main/scripts/bootstrap-macos.sh \
  | bash -s -- --host Irish-MBP
```

From an existing checkout, preview the complete plan before doing anything:

```sh
./scripts/bootstrap-macos.sh --host Irish-MBP --print-command
```

Then run the bootstrap as the normal login user:

```sh
./scripts/bootstrap-macos.sh --host Irish-MBP
```

The script installs Nix when needed, clones or reuses the checkout, validates
the selected host architecture, backs up conflicting system files, and performs
the initial nix-darwin activation. nix-homebrew installs Homebrew as part of
that activation. The Mac's local hostname is the default, but `--host` is
recommended for a new machine. Use `--repo PATH` for a non-standard checkout.

## Bootstrapping NixOS

Clone the repository once, then activate the matching flake host from the
checkout. The explicit Nix option is needed only for a fresh installation that
has not enabled flakes yet:

```sh
mkdir -p "$HOME/Documents/github.com/X0mbiRapt0r"
nix-shell -p git --run \
  'git clone https://github.com/X0mbiRapt0r/nix.git "$HOME/Documents/github.com/X0mbiRapt0r/nix"'
cd "$HOME/Documents/github.com/X0mbiRapt0r/nix"
sudo nixos-rebuild switch \
  --flake ".#Irish-MBP-2013" \
  --option experimental-features "nix-command flakes" \
  -L
```

The first activation installs the shared Home Manager configuration and `nrs`
helper. Later deployments are simply `nrs`, which fast-forwards a clean Linux
checkout before rebuilding.

## Validation

These checks are safe to run before activation:

```sh
nix fmt -- --check flake.nix home/**/*.nix hosts/*/configuration.nix hosts/*/host_*.nix modules/*.nix
nix flake check --no-build --all-systems --no-write-lock-file
nix flake check --no-write-lock-file
bash -n scripts/*
git diff --check
```

The generated `hardware-configuration.nix` is intentionally excluded from the
formatting command. None of these commands rebuilds or activates a host;
`nix-switch` is the explicit activation step.

## Update policy

The flake follows rolling nixpkgs, Home Manager, and nix-darwin inputs while
`flake.lock` keeps Nix inputs reproducible between deliberate `nfu` updates.
Homebrew metadata and packages intentionally update during activation, so
Homebrew-managed applications are not pinned by `flake.lock`.
`system.stateVersion` and `home.stateVersion` are compatibility baselines, not
package-version selectors, and should only change after reviewing the relevant
migration notes.

The normal deployment flow is deliberately one-way:

1. Make configuration changes on a Mac, then commit and push them.
2. When intentionally updating flake inputs, run `nfu` separately from the
   clean Mac checkout; it commits and pushes `flake.lock` itself.
3. Run `nrs` on a NixOS host; it fast-forwards the checkout and activates
   the already-published configuration and lock file.

Avoid running `nfu` on deployment-only hosts unless that machine is
deliberately taking over as the publishing checkout.

This is a public repository. Do not commit secrets, credentials, private keys,
or machine-local state.

## License

This repository is licensed under the [GNU General Public License v3.0](LICENSE).
