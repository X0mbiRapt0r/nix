# Unified Nix configuration

This flake manages a small set of NixOS and Apple Silicon macOS hosts with
shared Nix, Home Manager, and shell configuration. macOS applications are
declared through nix-darwin and nix-homebrew; NixOS host policy stays with the
host that needs it.

## Hosts

- `Irish-MBP` and `QTM-Irish-MBA`: Apple Silicon macOS systems managed by
  nix-darwin.
- `XR-PC`: an x86_64 NixOS gaming system.

## Layout

- `flake.nix` declares inputs, hosts, formatters, and validation checks.
- `modules/` contains shared system and macOS configuration.
- `home/irish/` contains shared and platform-specific Home Manager modules.
- `hosts/` contains the policy and hardware configuration unique to each host.
- `scripts/` contains explicit bootstrap, update, switch, and cleanup helpers.

## Helper commands

Home Manager exposes these scripts in `~/.local/bin`:

- `nix-switch` builds and activates the selected host. On `XR-PC`, it first
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

From a checkout, preview the first activation command before doing anything:

```sh
./scripts/bootstrap-macos.sh --host Irish-MBP --print-command
```

Then run the bootstrap as the normal login user:

```sh
./scripts/bootstrap-macos.sh --host Irish-MBP
```

The script can install Nix, clone or reuse the checkout, back up conflicting
system files, and perform the initial nix-darwin activation. nix-homebrew
installs Homebrew as part of that activation. Use `--repo PATH` when the
checkout is somewhere non-standard.

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
`flake.lock` keeps deployments reproducible between deliberate `nfu` updates.
`system.stateVersion` and `home.stateVersion` are compatibility baselines, not
package-version selectors, and should only change after reviewing the relevant
migration notes.

The normal deployment flow is deliberately one-way:

1. Make configuration changes on a Mac, then commit and push them.
2. When intentionally updating flake inputs, run `nfu` separately from the
   clean Mac checkout; it commits and pushes `flake.lock` itself.
3. Run `nrs` on `XR-PC`; it fast-forwards the checkout and activates the
   already-published configuration and lock file.

Avoid running `nfu` on deployment-only hosts unless that machine is
deliberately taking over as the publishing checkout.

This is a public repository. Do not commit secrets, credentials, private keys,
or machine-local state.
