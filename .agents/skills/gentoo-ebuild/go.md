# Go ebuilds

Sources: Gentoo wiki "Writing go Ebuilds"
<https://wiki.gentoo.org/wiki/Writing_go_Ebuilds> and "Go ebuild tricks"
<https://wiki.gentoo.org/wiki/Go_ebuild_tricks>, `go-module.eclass`.
General ebuild rules: `reference.md`.

## Eclass basics

If the top-level directory has a `go.mod`, inherit `go-module` (EAPI
7/8/9). Exports `src_unpack` (and `src_configure` — compile-env setup —
on EAPI 9) unless `GO_OPTIONAL=1`; **no `src_compile`/`src_install`** —
write them yourself with `ego` (the eclass `go` wrapper: dies on
failure, works with `nonfatal`) plus `dobin`/`default`.

- src_unpack default: deps tarball → unpack + `ego mod verify`
  (nonfatal-able); upstream `vendor/` dir → just verify; `EGO_SUM` set
  → QA warning only (deprecated, not yet fatal — see the sourcing
  options below). `EGO_VENDOR` is dead.
- BDEPEND needs `>=dev-lang/go-<ver>:=` matching the `go` directive in
  go.mod — install-time QA (`go_ver_check`) dies without it; the slot
  operator requires EAPI 8. Read the floor from go.mod, not from
  upstream README.

## Dependency sourcing (the central problem)

Go ebuilds must ship *every* module. Four options, in order of
consideration:

1. **Upstream `vendor/` directory** — just inherit; no SRC_URI extra,
   no tarball. Check for it first.
2. **EGO_SUM** (deprecated upstream — the wiki refuses to document it;
   still fully functional and **preferred in slonko**, see
   `slonko.md`) — no tarball to host or bump; per-module distfiles
   come from the go proxy. The eclass only QA-warns (no fatal yet)
   and there is no real replacement that avoids hosting:

   ```bash
   EGO_SUM=(
       "github.com/beorn7/perks v1.0.1"
       "github.com/beorn7/perks v1.0.1/go.mod"
   )
   go-module_set_globals
   SRC_URI+="${EGO_SUM_SRC_URI}"
   ```

   Generate from go.sum: `cat go.sum | cut -d" " -f1,2 | awk '{print
   "\t\"" $0 "\""}'` (or dev-go/get-ego-vendor). Omit the `h1:`
   hashes — the parser accepts them, but go re-verifies against
   go.sum at build time anyway. The list may be pruned to go.mod's
   require set; builds fine with fewer entries than go.sum
   (tibber-exporter pattern). Costs: large ebuild + Manifest, the
   deprecation QA notice, and exposure to goproxy distfile poisoning
   (below). `EGO_VENDOR` is dead — die on sight.
3. **Dependency tarball** (the tree's favored direction; zero ebuild
   bloat, but you host a tarball per version) — `go mod download`
   cache packed as `${P}-deps.tar.xz`; the base dir **must** be named
   `go-mod`:

   ```bash
   cd /path/to/unpacked/source
   GOMODCACHE="${PWD}"/go-mod go mod download -modcacherw
   XZ_OPT='-T0 -9' tar -acf ${P}-deps.tar.xz go-mod
   ```

   `SRC_URI+=" https://host/.../${P}-deps.tar.xz"` (rename `->
   ${P}-deps.tar.xz` is cosmetic). Host on a git-forge release
   (tag = ${P}) or any wget-reachable URL (no captcha/cookies).
   **gentoo-golang-dist** (GitHub actions, like gentoo-crate-dist)
   builds these per tag — request via bug (Repository URL, initial
   tags, special go args); or self-host via
   projg2/golang-dist-mirror-action. Projects with go.mod in a
   subdirectory: run the commands *there*, or the tarball is
   incomplete.
4. **Vendor tarball** (smaller; misses C/C++ sources of modules —
   build-test it): `go mod vendor` then tar `vendor/`.

## Skeleton

```bash
EAPI=8
inherit go-module

SRC_URI="https://github.com/O/R/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"
SRC_URI+=" ${P}-deps.tar.xz"

BDEPEND=">=dev-lang/go-1.23:="   # floor from go.mod `go` directive

src_compile() {
    ego build -o bin/${PN} -trimpath -ldflags "-X main.version=${PV}"  # or emake if upstream has a Makefile
}

src_install() {
    dobin bin/${PN}
    einstalldocs
}

src_test() {
    ego test ./...
}
```

- Parallelism: the eclass adds `-p=$(makeopts_jobs)` via GOFLAGS.
- Build tags (the Go "--enable-foo"): `src_configure() { GOFLAGS+=" -tags=external_libzstd"; }`
  — note the `+=` and the word-splitting quirks (golang #27368/#27282);
  README syntax often differs from what GOFLAGS needs.
- Upstream Makefile projects: `emake build` (act, go-md2man style);
  `ego build` only when building directly.

## distfile/goproxy poisoning (slonko lesson, 2026-10)

Portage shuffles the `mirror://goproxy/` list (proxy.golang.org +
goproxy.io); **goproxy.io serves HTML junk** that gets digested into
the Manifest at `ebuild digest` time — builds then fail go's
`SECURITY ERROR: checksum mismatch` (go.sum is the ground truth).
- Never "fix" by editing EGO_SUM/go.sum hashes.
- Verify the real bytes: `go mod download all` in the unpacked source
  (go's own TLS path), then seed `/var/cache/distfiles` from
  `~/go/pkg/mod/cache/download` (keep the `%2F`-escaped names) and
  hand-write the Manifest (`DIST name size BLAKE2B SHA512`,
  **BLAKE2B-512** = plain `b2sum`, not `-l 256`).
- go.sum `h1:` hashes are dirhash, NOT raw sha256: `.mod` h1 =
  double-sha256 trick; `.zip` h1 = hash of zip *contents* — trust the
  `.ziphash` sidecar in GOMODCACHE.
- Durable fix (system edit, declined so far): `/etc/portage/mirrors`
  with `goproxy https://proxy.golang.org`.

## Live ebuilds (-9999)

`git-r3` AFTER go-module on the inherit line, no SRC_URI, and:

```bash
src_unpack() {
    git-r3_src_unpack
    go-module_live_vendor   # skip when upstream vendors (lazygit)
}
```

## Unbundling C/C++ libraries

Detect: a *vendor* tarball build failure (it lacks C sources) → find
the failing go package in the log → read its `#cgo` lines. Prefer the
upstream switch to system libs:

- build-tag switches: `GOFLAGS+=" -tags=external_libzstd"` +
  `DEPEND="app-arch/zstd[static-libs]"` (dnsx pattern).
- `#cgo` define patches: `// #cgo CFLAGS: -DLIBWEBP_NO_SRC` style
  (gowebp/libwebp pattern) via PATCHES on the vendored copy.

## Upgrading a single dependency

Unpack the source, `git init && git add . && git commit -m initial`
for an easy diff, then `go get -x -u module@v1.5.2`; drop stale
entries (`sed -i -e '/module.*oldver/d' go.mod go.sum` — go may still
build the old copy otherwise). Apply the resulting diff as a PATCHES
entry (it touches go.mod+go.sum) and regenerate the dependency
tarball.

## LICENSE

Statically linked → every module's license must be listed. Generate:

```bash
printf 'LICENSE+=" '; go-licenses report ./... 2>/dev/null |
awk -F ',' '{ print $NF }' | sort --unique |
sed -e "$(sed -n -E 's|^(\S+)\s*=\s*(\S+)$|s/\1/\2/;|p' /var/db/repos/gentoo/metadata/license-mapping.conf)" |
tr '[:space:]' ' '; printf '"\n'
```

(`dev-go/go-licenses`; SPDX→Gentoo mapping via license-mapping.conf —
e.g. `BSD-3-Clause` → `BSD`. `dev-go/lichen` is the binary-scanning
alternative.)

## Symptoms → causes

| Symptom | Cause | Fix |
|---|---|---|
| `SECURITY ERROR: checksum mismatch` at build | poisoned distfiles (goproxy.io junk in Manifest) | see distfile/goproxy section; re-digest from clean bytes |
| `cannot find package`/missing module with vendor tarball | vendor dir incomplete for C-using modules | switch to a deps tarball |
| install-time die `go.mod requires go >= X` style QA | BDEPEND go floor missing/low | `>=dev-lang/go-X:=` (EAPI 8) |
| `QA Notice: ... uses EGO_SUM which is deprecated` | EGO_SUM ebuild | harmless for now — keep until it turns fatal; don't churn to tarballs without need |
| undefined C symbols / wrong lib linked | bundled C lib built instead of system one | build tags / #cgo patch (unbundling) |
| tests try to fetch modules (network sandbox) | deps tarball missing test deps, or live vendor missing | regenerate tarball including test deps (`go mod download` covers them) |
