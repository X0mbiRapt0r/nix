# Unified Nix configuration

This flake manages a small set of NixOS and Apple Silicon macOS hosts with
shared Nix, Home Manager, and shell configuration. macOS applications are
declared through nix-darwin and nix-homebrew; NixOS host policy stays with the
host that needs it.

## Hosts

- `Irish-MBP`: an Apple Silicon macOS system managed by nix-darwin.
- `Irish-MBP-2013`: a 2013 Intel MacBook Pro running NixOS with Xfce and Steam.
- `Irish-PC`: an x86_64 NixOS gaming system.
- `QTM-Irish-MBA`: an Apple Silicon work Mac managed by nix-darwin.
- `XR-NAS`: a headless x86_64 NixOS storage and services host.

## Layout

- `flake.nix` declares inputs, hosts, formatters, and validation checks.
- `modules/` contains configuration shared by multiple hosts.
- `home/irish/` contains shared and platform-specific Home Manager modules.
- `hosts/` contains each host's policy, hardware configuration, and private
  `services/` modules that are not reused elsewhere.
- `packages/` contains packages required by host-specific services.
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
recommended for a new machine. The standard macOS checkout is iCloud Drive's
`Documents/Code/nix`; use `--repo PATH` for a non-standard checkout.

## Bootstrapping NixOS

Clone the repository once, then activate the matching flake host from the
checkout. The explicit Nix option is needed only for a fresh installation that
has not enabled flakes yet:

```sh
mkdir -p "$HOME/Documents/Code"
nix-shell -p git --run \
  'git clone https://github.com/X0mbiRapt0r/nix.git "$HOME/Documents/Code/nix"'
cd "$HOME/Documents/Code/nix"
sudo nixos-rebuild switch \
  --flake ".#Irish-MBP-2013" \
  --option experimental-features "nix-command flakes" \
  -L
```

The first activation installs the shared Home Manager configuration and `nrs`
helper. Later deployments are simply `nrs`, which fast-forwards a clean Linux
checkout before rebuilding.

## Work Git identity

`QTM-Irish-MBA` loads its default Git author identity from
`~/.config/git/work.inc`. Provision that host-local file before activating the
work Mac; it must contain only the private `[user]` name and email settings.
Personal hosts use the public identity declared by Home Manager and do not load
this file.

Authentication remains separate from commit identity. The work Mac uses macOS
Keychain through packaged Git.

Private restore copies live under `iCloud Drive/Backups/Hosts/<host>` and
mirror their absolute destination from the host filesystem. For example,
`Hosts/XR-NAS/etc/xombiraptor/ntfy.env` restores to
`/etc/xombiraptor/ntfy.env`, while the work identity restores beneath the
matching user's `.config/git` directory. Restore service credentials as
`root:root` mode `0600`; the backup tree is not read directly by NixOS.

## SSH setup

The work Mac declares `qtm-nuc`, `QTM-NUC`, and `qtm-nuc.local` for the shared
Debian NUC, using its own `~/.ssh/id_ed25519`. The concrete username and
hostname remain in the host configuration. These aliases are installed only on
`QTM-Irish-MBA`.
The personal Mac similarly declares host aliases using its separate key. The
concrete usernames and hostnames remain in the host configuration.

Every NixOS host advertises its `.local` name using Avahi. The client and
server must be on a network where mDNS works; the aliases do not provide DNS
or remote routing by themselves.

Generate the client key on the work Mac, only if it does not already exist:

```sh
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -a 64 -f ~/.ssh/id_ed25519 -C QTM-Irish-MBA
/usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

Use the same commands on `Irish-MBP` with `-C Irish-MBP`; each Mac keeps its
own keypair and receives access only to its corresponding hosts.

Choose a passphrase. Only the `.pub` file belongs in Git. The private key
stays on the client; the NUC does not need a copy. Home Manager writes only
the key's runtime path, never its contents. Apple's SSH client uses Keychain
and the local agent for subsequent connections, without forwarding the agent.

Keep private restore copies in the host-mirrored iCloud backup tree, not this
checkout. `.gitignore` is not encryption and does not protect against
force-adds or `path:` flakes copying ignored files into the Nix store. Never
reference private files with Nix path literals, `builtins.readFile`, or
`home.file.source`.

Before activating the Mac configuration, review any existing `~/.ssh/config`
and migrate entries that should remain; Home Manager backs up an unmanaged
file as `config.before-hm`, but does not automatically merge its contents.

The shared Debian NUC is managed outside this flake. Its server-side SSH policy,
including password access for other users, remains manual. The work Mac still
uses its configured key when connecting as `irish`; normal use is
`ssh qtm-nuc`. Verify the replacement NUC's host-key fingerprint through its
console or another trusted connection before accepting it on the Mac.

The three personal NixOS hosts declare only the personal Mac's public key.
Those public client keys are centralized in `flake.nix`; private keys remain on
their respective Macs and never enter Git or Nix.

For a new personal host, first use its existing password-based connection to
bootstrap the Mac's public key. Replace `HOST` with the host's current IP or
resolvable hostname. Verify the server's host-key fingerprint through its local
console or another trusted connection before accepting a new SSH host prompt:

```sh
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Then run this from `Irish-MBP`:

```sh
cat ~/.ssh/id_ed25519.pub | ssh USER@HOST \
  'umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys'
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes \
  -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no \
  USER@HOST 'hostname; whoami'
```

After that succeeds, publish the Nix change and keep the working SSH session
open while running `nrs` on that host. Test its alias from a separate Mac
terminal before closing the original session:

```sh
ssh irish-pc 'hostname; whoami'
ssh mbp-2013 'hostname; whoami'
ssh xr-nas 'hostname; whoami'
```

Once the activated configuration and alias both work, remove the bootstrap
copy of the Mac key from `~/.ssh/authorized_keys` on the server. NixOS keeps
the declarative copy in `/etc/ssh/authorized_keys.d/irish`; removing the
bootstrap copy ensures later key rotation or revocation remains controlled by
the flake. Repeat the bootstrap, activation, verification, and cleanup for one
host at a time.

## XR-NAS operations

XR-NAS mounts the single-device Btrfs data filesystem at `/srv/data` and shares
only `/srv/data/share` through authenticated SMB. `smartd` monitors every
detectable drive, weekly TRIM discards unused SSD blocks, and monthly Btrfs
scrubs verify every declared Btrfs filesystem. SMART warnings are written to
the journal and sent to logged-in sessions. Scrubs, snapshots, and the iCloud
mirror all remain on the NAS and are not substitutes for an independent
backup.

After activating a configuration change, inspect storage monitoring with:

```sh
systemctl status smartd
systemctl list-timers 'btrfs-scrub-*'
journalctl -u smartd
sudo smartctl -x /dev/sda
sudo smartctl -x /dev/nvme0
sudo btrfs scrub status /
sudo btrfs scrub status /srv/data
```

The private ntfy server listens only on loopback and is reached through the
outbound Cloudflare Tunnel. Both services load their credentials from
root-owned files under `/etc/xombiraptor`. The daily HostlistCompiler job also
runs locally; its output remains private systemd state until a separate
publication and access model is deliberately configured.

AIOStreams and Comet also use the outbound tunnel. Their HTTP ports are bound
to loopback, Comet's PostgreSQL database is reachable only on a private Podman
network, and container output is retained by journald. Before the first
activation, restore these files to `/etc/xombiraptor` with mode `0600`:

```text
/etc/xombiraptor/aiostreams.env
  SECRET_KEY=<openssl rand -hex 32>
  AIOSTREAMS_AUTH=irish:<strong password>
  AIOSTREAMS_AUTH_PERMISSIONS=irish=admin

/etc/xombiraptor/comet.env
  POSTGRES_PASSWORD=<openssl rand -hex 32>
  DATABASE_URL=comet:<same PostgreSQL password>@comet-postgres:5432/comet
  ADMIN_DASHBOARD_PASSWORD=<strong password>
  CONFIGURE_PAGE_PASSWORD=<strong password>
```

Add two public hostnames to the existing remotely managed XR-NAS tunnel:

```text
streams.xombiraptor.net -> http://localhost:3000
comet.xombiraptor.net   -> http://localhost:8000
```

After activation, verify the local services before testing Cloudflare or
configuring Stremio:

```sh
systemctl status podman-aiostreams podman-comet podman-comet-postgres
curl --fail http://127.0.0.1:3000/api/v1/status
curl --fail http://127.0.0.1:8000/health
journalctl -u podman-aiostreams -u podman-comet -u podman-comet-postgres
```

Complete first-run setup at `https://streams.xombiraptor.net/stremio/configure`
and `https://comet.xombiraptor.net/configure`. Start with local Comet as the
only AIOStreams discovery addon and AllDebrid as the service; add fallback
providers only after this baseline has been proven reliable.

The iCloud mirror synchronises into `/srv/data/icloud` each day after taking a
read-only pre-sync snapshot under `/srv/data/snapshots/icloud`. It retains 90
snapshots and records a successful run at
`/var/lib/icloud/last-mirror-success`. Authentication state and notification
credentials stay under `/var/lib/icloud` and `/etc/xombiraptor`; they must
never be added to the repository. Useful checks are:

```sh
systemctl status icloud-mirror.timer icloud-mirror.service
journalctl -u icloud-mirror.service
stat /var/lib/icloud/last-mirror-success
```

## Validation

These checks are safe to run before activation:

```sh
nix fmt -- --check flake.nix home/**/*.nix hosts/*/configuration.nix hosts/*/host_*.nix hosts/*/services/*.nix modules/*.nix packages/*.nix
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
