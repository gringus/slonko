# Rust ebuilds

Sources: Gentoo wiki "Writing Rust ebuilds"
<https://wiki.gentoo.org/wiki/Writing_Rust_ebuilds>,
Project:Rust/sys_crates <https://wiki.gentoo.org/wiki/Project:Rust/sys_crates>,
eclass sources (`cargo.eclass`, `rust.eclass`, `rust-toolchain.eclass`).
General ebuild rules: `reference.md`.

## Eclass choice

| Situation | Eclass |
|---|---|
| Upstream builds with cargo (the norm) | `cargo` (pulls in `rust` + `rust-toolchain`) |
| Rust needed by a non-cargo build (cmake/meson/autotools components, or the rust toolchain used directly) | `rust` (slotted toolchain) |
| Package ships prebuilt rust with no toolchain needed | neither |

- Both EAPI 8 only. `cargo` sets `RUST_MIN_VER` (currently ≥ 1.71.1)
  itself; set `RUST_MIN_VER` higher only if the code needs it (read
  upstream Cargo.toml `rust-version` / changelog).
- Combine with another primary build eclass: `CARGO_OPTIONAL=1` (cargo)
  or `RUST_OPTIONAL=1` (rust) before inherit, then call `cargo_src_*` /
  `rust_pkg_setup` yourself and add `${RUST_DEPEND}` to BDEPEND where
  needed.
- `cargo` adds `debug` to IUSE automatically; `cargo_src_*` are
  exported unless optional.
- Tight Rust+LLVM coupling: `RUST_NEEDS_LLVM=1` + `inherit llvm-r1` +
  `LLVM_COMPAT=( … )` → llvm_slot_x-gated `RUST_DEPEND`; dies if an
  LLVM slot in LLVM_COMPAT has no matching rust slot.
  `RUST_MULTILIB=1` for multilib.
- Manual variant (bpftrace): `RUST_OPTIONAL=1` and handle toolchain +
  LLVM deps yourself (`$(llvm_gen_dep 'llvm-core/llvm:${LLVM_SLOT}=' …)`).

## Dependency sourcing (decide the shape first)

Rust deps ("crates") are statically compiled into the binary — the
LICENSE of every crate must be in LICENSE, and native libs pulled by
`-sys` crates belong in RDEPEND.

1. **gentoo-crate-dist vendor tarball (preferred — the current tree
   style)**: no giant CRATES list; bumps don't need regenerating deps.

   ```bash
   CRATES=" "    # silence the eclass check
   SRC_URI="
   https://github.com/<repo>/<name>/archive/.../${P}.tar.gz
   https://github.com/gentoo-crate-dist/<name>/releases/download/${PV}/${P}-crates.tar.xz
   "
   src_unpack() { cargo_src_unpack; }   # or rely on the default
   ```

   The tarball contains `cargo_home/gentoo/<crate>/…` — plain unpack
   populates `ECARGO_VENDOR` directly. A `-> ${P}-deps.tar.xz` rename
   is cosmetic (vaultwarden pattern) and fine. To get a new package
   added, file a gentoo-crate-dist request (Repository URL, initial
   tags, special pycargoebuild args). Alternative:
   `cargo vendor > vendor-config.toml && mv vendor-config.toml vendor/`,
   `XZ_OPT='-T0 -9' tar -acf vendor.tar.xz vendor` — self-made
   tarballs need extra config surgery (see wiki).
2. **CRATES list** (plain crates.io deps): generate with
   `pycargoebuild ./` in the source dir, format `name@version` (the
   legacy hyphen syntax works but is much slower), and
   `SRC_URI="${CARGO_CRATE_URIS}"`. Each `.crate` is unpacked into
   `ECARGO_VENDOR` with a generated `.cargo-checksum.json`.
3. **git deps** (crate not on crates.io or upstream needs a specific
   commit): `declare -A GIT_CRATES=( [crate]="<repo-url>;<commit>[;<crate>-%commit%/<path-to-cargo.toml-dir>]" )`.
   The commit comes from upstream Cargo.lock (grep it) or the GitHub
   tag URL. The eclass looks for the crate at
   `${WORKDIR}/<crate>-<commit>` by default; third field overrides the
   path (relative to ${WORKDIR}, `%commit%` substituted; the key in []
   must match the crate name in its Cargo.toml). A Cargo.toml dep on a
   git *branch* (unpinned) means the versioned ebuild cannot work —
   make it live or vendor that crate.

pycargoebuild needs the portage group. Its output usually needs: manual
HOMEPAGE/DESCRIPTION (if missing from Cargo.toml), LICENSE verification
(cargo-licenses are SPDX, Gentoo names differ sometimes), and KEYWORDS.

## Skeleton (cargo, vendor tarball)

```bash
EAPI=8
CRATES=" "
RUST_MIN_VER="1.81.0"   # only if needed above the eclass default
inherit cargo

SRC_URI="...upstream tarball... "
SRC_URI+=" https://github.com/gentoo-crate-dist/${PN}/releases/download/${PV}/${P}-crates.tar.xz"

LICENSE="Apache-2.0"
# Dependent crate licenses
LICENSE+=" BSD ISC MIT Unicode-3.0"

RDEPEND="dev-libs/openssl:="
DEPEND="${RDEPEND}"
# Rust does not respect CFLAGS/LDFLAGS:
QA_FLAGS_IGNORED="usr/bin/${PN}"

src_configure() {
    local myfeatures=( $(usev fix) )
    cargo_src_configure
}
```

- Features: `local myfeatures=( $(usev foo) ); cargo_src_configure`.
  To allow only *some* default features:
  `cargo_src_configure --no-default-features` + myfeatures.
- Workspaces: `cargo_src_install --path <member>`; for tests
  `cd <member> || die; cargo_src_compile` (test discovery needs cwd).
- Tests: `cargo_src_test` (or `--no-fail-fast`); skip entries via
  `local CARGO_SKIP_TESTS=( tests::network … )` (must be an array).
  Suites hitting the network: `PROPERTIES="test_network"` +
  `RESTRICT="test"` (cargo-audit pattern) or deselect.
- The `pkg-config` **crate** in the dep tree → `virtual/pkgconfig` in
  BDEPEND and `export PKG_CONFIG_ALLOW_CROSS=1` (cross-compilation).
- `cargo_env` runs a command with the eclass cargo environment; use it
  for custom build systems instead of hand-setting CARGO_HOME/PATH.

## Updating / overriding crates

SemVer governs everything — only override with compatible versions
(`cargo tree` / `cargo metadata` to check; beware multiple
semver-incompatible versions of the same crate in the graph).

- Substitute a newer compatible crate in CRATES (or the vendored
  config) → call `cargo_update_crates` in src_prepare (before the
  build-system prepare; e.g. `cmake_src_prepare`).
- `CRATE_PATHS_OVERRIDE="openssl@0.10.35 openssl-sys@0.9.65"` — paths
  overrides for vendored/shipped crates; does not respect version
  constraints or the lock file. If the package's own cargo config also
  overrides crates.io, strip the conflicting `[source.crates-io]`
  block: `sed -i '/\[source.crates-io\]/,+2d'
  "${ECARGO_HOME}"/config.toml` in src_unpack (rust-1.54 pattern).
- Manually patching a crate: must update `.cargo-checksum.json` for
  every changed file — last resort, prefer a compatible crate bump.

## Live ebuilds (-9999)

- Drop CRATES and SRC_URI; inherit `git-r3` AFTER cargo on the inherit
  line; `src_unpack() { git-r3_src_unpack; cargo_live_src_unpack; }`
  (fetches deps and vendors them offline).
- Unpinned git deps in Cargo.toml → cargo wants network later →
  `can't update a git repository in the offline mode` → add
  `cargo_src_configure --frozen`.

## Unbundling -sys crates

`cargo tree --all-features` to find them and which features pull them;
native libs go into RDEPEND. Most -sys crates default to *vendored* C
libs (upstream bug #709568) — check the crate's build.rs for the
controlling envvar and set it in src_configure/global scope:

| Crate | Recipe |
|---|---|
| openssl-sys | `export OPENSSL_NO_VENDOR=1` + `dev-libs/openssl:=` |
| libsqlite3-sys | `export LIBSQLITE3_SYS_USE_PKG_CONFIG=1` + `dev-db/sqlite:3` |
| libssh2-sys | `export LIBSSH2_SYS_USE_PKG_CONFIG=1` + `net-libs/libssh2` |
| zstd-sys | `export ZSTD_SYS_USE_PKG_CONFIG=1` + `app-arch/zstd:=` |
| libgit2-sys | `export LIBGIT2_NO_VENDOR=1` + `dev-libs/libgit2` (≥0.16.0) |
| jemalloc-sys / tikv- | `export JEMALLOC_OVERRIDE="${ESYSROOT}/usr/$(get_libdir)/libjemalloc.so"` + `>=dev-libs/jemalloc-5.3.0` (tikv- also `CARGO_FEATURE_UNPREFIXED_MALLOC_ON_SUPPORTED_PLATFORMS=1`; min version decodable from crate version suffix) |
| rocksdb | `ROCKSDB_LIB_DIR`/`ROCKSDB_INCLUDE_DIR`/`SNAPPY_LIB_DIR` to ESYSROOT paths (exact version match only) |
| bzip2-sys | wants system lib but needs `bzip2.pc` which Gentoo doesn't ship — write a minimal .pc into `${T}/pkg-config` + `export PKG_CONFIG_PATH` |
| libdeflate-sys | pins a very specific system version; strip the pin |

If any revdep enables a `static` feature of the -sys crate, unbundling
is off the table. Also check features like `bundled`/`static` in
Cargo.toml and drop them via `--no-default-features`/myfeatures where
possible.

## Symptoms → causes

| Symptom | Cause | Fix |
|---|---|---|
| `error: no matching package named X found` (fetch/compile) | crate missing from CRATES / vendor tarball | regenerate CRATES (pycargoebuild), bump vendor tarball, or add crate |
| `Failed to resolve 'crates.io'` / network sandbox hit in compile | cargo trying to download at build time | CRATES missing a dep; or unpinned git dep → `--frozen` |
| `can't update a git repository in the offline mode` | unpinned git deps | `cargo_src_configure --frozen` |
| `did not find expected file … .cargo-checksum.json` / checksum mismatch | hand-patched crate without checksum update, or stale vendor tarball | update checksums / re-vendor |
| QA Notice: file(s) under /usr/bin with unset LDFLAGS | rust ignores CFLAGS/LDFLAGS | `QA_FLAGS_IGNORED="usr/bin/${PN}"` (expected, not a bug) |
| LICENSE complaints on crates | every compiled-in crate's license required | `cargo license`, translate SPDX → Gentoo, `LICENSE+=" …"` |
| Tests try to reach the network | rustsec DB, registry checks, etc. | `CARGO_SKIP_TESTS` / `PROPERTIES="test_network"` + RESTRICT |
| `virtual/pkgconfig` missing / cross failure | pkg-config crate present | BDEPEND + `PKG_CONFIG_ALLOW_CROSS=1` |

## Version constraints

- `RUST_MIN_VER` / `RUST_MAX_VER` (rust.eclass, pre-inherit) pin the
  acceptable slot range; `cargo` enforces its own floor. Check
  upstream `rust-version` in Cargo.toml.
- `RUST_REQ_USE` adds USE deps on the toolchain (e.g. `clippy`).
- `rust_abi` (rust-toolchain) maps CHOST → rust triple — needed only
  when fetching prebuilt toolchains manually.
