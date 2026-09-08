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
- `modules/` contains shared system and platform-specific configuration.
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

## Work SSH setup

The work Mac declares `qtm-nuc` for the work automation host, using its own
`~/.ssh/id_ed25519`. The concrete username and hostname remain in the host
configuration. This alias is only installed on `QTM-Irish-MBA`.
The NUC advertises its `.local` name using Avahi; both hosts must be on a
network where mDNS works.

Generate the client key on the work Mac, only if it does not already exist:

```sh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -a 64 -f ~/.ssh/id_ed25519 -C QTM-Irish-MBA
/usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Choose a passphrase. Only the `.pub` file belongs in Git. The private key
stays on the client; the NUC does not need a copy. Home Manager writes only
the key's runtime path, never its contents. Apple's SSH client uses Keychain
and the local agent for subsequent connections, without forwarding the agent.

Prefer keeping private backups outside this checkout. `/.private/` is ignored
if a local backup is needed, but `.gitignore` is not encryption and does not
protect against force-adds or `path:` flakes copying the whole directory into
the Nix store. Never use a `path:` flake or a whole-directory source copy on
a checkout containing secrets, and never reference private files with Nix
path literals, `builtins.readFile`, or `home.file.source`.

Before activating the Mac configuration, review any existing `~/.ssh/config`
and migrate entries that should remain; Home Manager backs up an unmanaged
file as `config.before-hm`, but does not automatically merge its contents.

The NUC declares the work Mac's public key for `irish` and requires public-key
authentication, with root SSH, passwords, and keyboard-interactive login
disabled. Other hosts retain their existing policies.

Before activating this NUC configuration, install the same public key using
the existing login and verify a separate connection using only public-key
authentication. From the work Mac, this bootstrap command appends the public
key to the NUC's existing authorized keys:

```sh
cat ~/.ssh/id_ed25519.pub | ssh qtm-nuc \
  'umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys'
```

Verify
the NUC's host fingerprint through its console or another trusted connection:

```sh
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

On the Mac, compare that fingerprint on first connection, then test:

```sh
ssh -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no qtm-nuc 'hostname; whoami'
```

If the Mac configuration is not activated yet, use
`ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no qtm-nuc 'hostname; whoami'`.

Keep the existing session open during the later key-only activation and test
again from a new terminal. Normal use is `ssh qtm-nuc`; run `claude` inside
that remote session to work on the NUC. SSH setup does not configure a separate
Claude Desktop integration or grant passwordless sudo.

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
