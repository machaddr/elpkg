# elpkg

elpkg is the SomaLinux package manager. It installs signed binary packages from
`https://repo.somalinux.org/{arch}` and can build packages from Bash recipes
for repo maintenance.

## Features
- Binary install/upgrade/remove with file ownership tracking.
- Dependency resolution (repo metadata driven).
- Package integrity via SHA256 and optional OpenSSL signatures.
- Snapshot/restore for rollback.
- Recipe-based builds to produce repo artifacts.
- DB integrity checksums and `elpkg check` ownership verification.
- Per-file content hashes with `elpkg verify` and optional repair.
- Global install/remove hooks with allow/deny policies.
- Optional script environment cleaning / non-root execution via config.
- Conflict handling with `--overwrite` and upgrade/reinstall options.
- Transaction journal with rollback and optional auto-snapshots.
- Dependency constraints and virtual provides/conflicts.

## Layout
- Config: `/etc/elpkg/elpkg.conf` (or `elpkg/etc/elpkg.conf` in this repo).
- DB: `/var/lib/elpkg` (installed package records, file ownership, snapshots).
- Cache: `/var/cache/elpkg` (repo index, packages, sources).

## Common commands
```
elpkg sync
elpkg search bash
elpkg info bash
elpkg install bash
elpkg install --upgrade bash
elpkg install --reinstall bash
elpkg install --no-snapshot bash
elpkg remove bash
elpkg tx list
elpkg tx show <id>
elpkg tx rollback <id>
elpkg update
elpkg snapshot create baseline
elpkg snapshot restore baseline-<timestamp>
elpkg check
elpkg verify
elpkg verify --fix
```

## Repository format
`index.json` contains a list of packages with fields:
`name`, `version`, `release`, `arch`, `filename`, `sha256`, `size`, `deps`,
`provides`, `conflicts`, `description`.

To build a repo index from locally built packages:
```
elpkg repo index /path/to/repo
```
If `openssl_privkey` is set in the config, this will also create `index.json.sig`
and per-package `*.sig` files in the repo directory.

To build a patches index (for repo/patches):
```
elpkg repo patches-index /path/to/repo/patches
```

To sync patches from the repo:
```
elpkg patches sync
```

## Recipe format
Recipes live in `elpkg/recipes/*.sh` and follow a simple Bash format:
```
#!/bin/bash
set -euo pipefail

pkgname="example"
pkgver="1.2.3"
pkgrel=1
arch=("x86_64")
source=("https://example.org/example-${pkgver}.tar.gz")
sha256sums=("SKIP")
depends=("glibc")
provides=("libfoo")
conflicts=("oldfoo<2.0")

description="Example package"

build() {
  cd "$srcdir/example-$pkgver"
  ./configure --prefix=/usr
  make
}

package() {
  cd "$srcdir/example-$pkgver"
  make DESTDIR="$pkgdir" install
}
```

The build system sets:
- `srcdir` / `SRCDIR`: unpacked source directory
- `builddir` / `BUILDDIR`: build working directory
- `pkgdir` / `PKGDIR`: staging root for packaging
- `patchdir` / `PATCHDIR`: patches directory (from config if set)

## Notes
- For signed repos, place trusted public key(s) at `/etc/elpkg/trusted.pem`.
  Multiple keys can be comma-separated in `openssl_pubkey` for rotation.
- DB checksums are written alongside DB files as `.sha256`.
- Set `require_file_hashes = true` to enforce hashes for all installed packages.
- Hook scripts live in `/etc/elpkg/hooks.d` and are executed by phase:
  - `/etc/elpkg/hooks.d/pre_install.d/*`
  - `/etc/elpkg/hooks.d/post_install.d/*`
  - `/etc/elpkg/hooks.d/pre_remove.d/*`
  - `/etc/elpkg/hooks.d/post_remove.d/*`
  - or named with a `phase-` prefix in the base hooks dir.
  - `hooks_allowlist`/`hooks_denylist` control which scripts run.
- Transaction journals live under `/var/lib/elpkg/transactions` by default.
- Set `auto_snapshot = true` to create a snapshot before installs/removes.
- Use `--no-snapshot` to skip auto-snapshots for a single command.
- Control transactions with `tx_enabled`, `tx_dir`, and `tx_keep` in `elpkg.conf`.
- Config files under `/etc` are treated specially: if modified, new versions
  are installed as `.elpkg-new` files instead of overwriting.
- `elpkg verify --fix` repairs files only when the original package file is available.
- Script hardening options: `script_env_clean`, `script_keep_env`, `script_user`.
- Source checksums can be set to `SKIP` during development.

