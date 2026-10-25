---
name: gentoo-ebuild
description: >
  Write, update, version-bump, and debug Gentoo ebuilds and eclasses; fix
  ebuilds that fail to install. Use when creating or editing .ebuild files,
  troubleshooting failing builds/emerge errors, Manifest/digest work, USE
  flags, SLOTs, dependency (DEPEND/RDEPEND/BDEPEND) syntax, metadata.xml,
  patches in files/, systemd/OpenRC service packaging, acct-user/acct-group
  helpers, or QA with pkgcheck/pkgdev. Uses /usr/portage as the canonical
  example/eclass/license source. Triggers: "ebuild", "eclass", "portage
  package", "overlay", "version bump", "add a package to Gentoo", "USE flag",
  "SLOT", "KEYWORDS", "Manifest", "emerge failed", "build fails", "broken
  ebuild".
---

# Gentoo ebuild authoring

Reference material: `reference.md` in this directory (variable semantics, phase
functions, common-mistakes catalogue, eclass table). Read the section you need
before writing anything non-trivial. Do not guess variable semantics.

## Prime directives

- EAPI: **8 is the safe default** (universal eclass support); EAPI 9 is final
  (approved 2025) — fine for new non-`@system` ebuilds when their eclasses
  support it. Don't gratuitously re-EAPI-bump working ebuilds. Details:
  `reference.md`, EAPI table.
- An ebuild is a *bash snippet Portage sources* — quote like bash, but most
  variables are set by Portage: never assign to `P`/`PN`/`PV`/`PR`/`PVR`/
  `PF`/`A`/`D`/`T`/`WORKDIR`/`FILESDIR`. (`S` is yours to set when the default
  `${WORKDIR}/${P}` is wrong — but only then.)
- File lives at `<repo>/<category>/<PN>/<PN>-<PV>[-rN].ebuild`. Version
  suffixes: `_alpha/_beta` prereleases, `_pre` release-candidate, `_pN`
  upstream-patched. `-rN` = ebuild revision (bump the revision instead of
  re-releasing when only the ebuild changes).
- Before writing from scratch, look for an existing ebuild to copy and adapt:
  the tree at `/usr/portage` is the reference — `ls /usr/portage/<cat>/<pn>/`
  or grep for a similar package/build-system:
  `grep -rl 'inherit cargo' /usr/portage/*/` finds real examples per eclass.
  Prefer bumping/adapting an existing ebuild over writing a new one. Copying +
  adapting a similar tree ebuild is the normal workflow, not heroics.
- `/usr/portage/eclass/<name>.eclass` — read the eclass source (top comment
  block) for exact behavior of any inherit; it's the ground truth.

## Minimal skeleton

```bash
# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="One-line purpose, <=80 chars, no trailing period, no PN echo"
HOMEPAGE="https://example.com"
SRC_URI="https://example.com/${P}.tar.gz"

LICENSE="GPL-2"          # license NAME must exist in the tree's licenses/
SLOT="0"                 # 0 = replaceable; soname/compat slot otherwise
KEYWORDS="~amd64"        # ~arch=testing, arch=stable; "" = needs
                         # **/$pn in package.accept_keywords
# empty IUSE/DEPEND/RDEPEND/BDEPEND lines are omitted, not set to ""
```

Pick the build-system eclass, that's 90% of the work:

| Upstream build system | Eclass | Build phases collapse to |
|---|---|---|
| configure/Makefile (autotools) | `autotools` | `econf && emake` (auto `src_install` via `default`) |
| CMake | `cmake` | `cmake_src_*` (just inherit) |
| Meson/Ninja | `meson` | inherit only |
| Plain Makefile | none | `emake` / `emake DESTDIR="${D}" install` or manual `insinto`+`doins` |
| Python (setup.py/pyproject) | `distutils-r1` + `pypi` | `DISTUTILS_USE_PEP517=...`, `PYTHON_COMPAT`, `distutils_enable_tests` |
| Rust/Cargo | `cargo` (vendored `CRATES`) or new `rust.eclass` (EAPI 8, builds against slotted rust) | inherit + `cargo_src_*` / rust defaults |
| Go modules | `go-module` | inherit; deps from `-deps.tar.xz` (gentoo-golang-dist) or `go-module_live_vendor` |
| Ruby gem / cpan / etc. | `ruby-single`/`perl-module`… | check devmanual eclass list |

`pypi` eclass: set `PYPI_PN` when the project name/casing differs from PN
(`ImageHash`) **and** `PYPI_NO_NORMALIZE=1` when the sdist filename isn't
lowercase-normalized — both before `inherit`; the filename is lowercased even
with `PYPI_PN` alone. Inspect the sdist (`tar -tzf`) — if it ships a broken
test suite (missing `__init__.py`/helpers the git repo has), fetch the GitHub
tarball instead.

For VCS/live ebuilds (`-9999`): `git-r3` (`EGIT_REPO_URI`), `cmake`/autotools
variants; `KEYWORDS=""` always, and pin tags via `EGIT_COMMIT`/`tag` when
possible. Real examples: `grep -rl EGIT_REPO_URI /usr/portage/*/*/*.ebuild`.

## Dependency rules (the ones people get wrong)

- `RDEPEND` = runtime (shared libs the binary loads). `DEPEND` = build/link —
  idiomatic shape: `RDEPEND="…" DEPEND="${RDEPEND}"`, add headers-only extras
  to DEPEND. `BDEPEND` = build-time-only host tooling (codegen, make
  generators, pkg-config probes) since EAPI 7. `PDEPEND` = almost never
  correct (cycle-breaking / post-merge ordering only).
- Slot-pin with `:=` whenever a library is *linked against* a header'd lib:
  `dev-libs/openssl:=`.
- USE-conditional: `ssl? ( net-libs/nghttp2:= )`; define in `IUSE` (no `+`
  unless intentional default-on). `REQUIRED_USE` constraints: `|| ( )` ≥one,
  `^^ ( )` exactly one, `?? ( )` ≤one, `ssl? ( !libressl )` exclusion.
- Python deps inside `python_gen_cond_dep '...[${PYTHON_USEDEP}]'` when
  `DISTUTILS_SINGLE_IMPL` or multi-target.
- Never depend on whole `virtuals` "just in case"; depend on the concrete
  package when possible (`media-libs/libglvnd` etc. — check tree conventions).
- Services daemons: run-as user/group via `acct-user/<x>` + `acct-group/<x>`
  packages (see `reference.md`), not manual `enewuser`.

## Hard rules (non-exhaustive; full catalogue in reference.md)

- No upstream releases via `${PN}`-based SRC_URI guesswork — write the real URL
  with `${PV}`/`${P}` interpolated.
- `src_prepare` must call `default` (runs `eapply_user` = user's
  `/etc/portage/patches`). Patches go in `files/` via the `PATCHES=( ... )`
  array — no hand-rolled `patch -p1`.
- Never override/sanitize `*FLAGS` blindly: use `append-flags`/`replace-flags`
  from `flag-o-matic` *with a die-worthy reason and a comment*.
- `use_enable`, `use_with`, `usex` — not `if use foo; then echo --enable-foo`.
- Install into `${D}` via provided helpers (`dosym`, `insinto`/`doins`,
  `dodoc`, `doman`, `dobin`, `exeinto`…; `einstall` banned since EAPI 6 —
  `emake DESTDIR="${D}" install`). No `cp -r` into `/`. `fowners`/`fperms`
  fix ownership, not chmod after copy.
- systemd units: `systemd_dounit`, `newunit`, `systemd_enable_service`;
  OpenRC: `newinitd`/`newconfd` + `need_user` or acct deps. No manual .service
  copying.
- `LICENSE` must exist in `licenses/` (tree or overlay) — check
  `/usr/portage/licenses/` before inventing a name.
- Ebuilds inherit at most a handful of eclasses; prefer `default` phases over
  re-implementing them.

## Adding a test phase (Python/pytest)

- Test-only deps go in `BDEPEND="test? ( ... )"` with `PYTHON_USEDEP`, never
  DEPEND; keep `DEPEND="${RDEPEND}"`.
- distutils-r1: `distutils_enable_tests pytest` (or `unittest`). Non-distutils
  (python-single-r1): define `src_test() { epytest; }` — EPYTHON is already set.
- `epytest` plugin model: if `EPYTEST_PLUGINS` is unset, plugin autoload is
  OFF (`-p no:cov -p no:sugar …`) and addopts needing those plugins get
  stripped. With `EPYTEST_PLUGINS` set, only listed plugins load and **no
  stripping happens**. Set the minimal verified set at module scope, one per
  line — verify each by grepping the suite for its fixtures *and* marks
  (`mocker`, `httpx_mock`, `@pytest.mark.flaky` …). Django packages need
  `pytest-django` + `pytest-env` loaded or their ini env vars never apply.
- `EPYTEST_IGNORE`/`EPYTEST_DESELECT`/`EPYTEST_PLUGINS` all at module scope
  (celery ebuild style), one entry per line, per-entry `# why` comments.
- Upstream pytest config from `pyproject.toml` (`[tool.pytest]` /
  `[tool.pytest_env]`, pytest ≥9) is picked up automatically when tests run
  from the project root.
- Packages that read system config at import (`load_dotenv('/etc/…')`) or
  `mkdir` runtime dirs during settings import need env overrides in
  `src_test`: pre-set the vars (`local -x …`) — `load_dotenv` uses
  `override=False`, so pre-set env wins; redirect data paths into `${T}`.
- Prefer upstream test deps in TEST BDEPEND over deselects when cheap
  (e.g. a package needing `django-auditlog` imports it unconditionally in
  tests even though it's an optional runtime USE dep — install it for tests
  and force-enable via env).

## Build-time-only python (codegen in cmake/meson builds)

Eclass choice per the Python guide
(<https://projects.gentoo.org/python/guide/eclass.html>): python used purely
at build time (codegen, translators, doc builds) → `python-any-r1`; python
needed at runtime → `python-single-r1`/`python-r1`/`distutils-r1`. Do NOT put
python deps in RDEPEND "because the old ebuild did" — verify runtime use
first (check the installed file list for `.py` files; cmake codegen macros
like jinja templates run at build time only).

- **The trap**: `python-any-r1`'s `python_setup` picks the newest installed
  impl from `PYTHON_COMPAT` — it does NOT know which impl has the build-time
  python modules installed (jinja2, mako, …). Upstream build systems
  (e.g. workrave's cmake `DBus.cmake`) silently fall back to
  `python -m venv` + `pip install` when the module import fails, which the
  network sandbox then blocks with `Could not find a version that satisfies
  the requirement`.
- **Required three-part pattern** (module deps with any-r1):

  ```bash
  BDEPEND="dbus? ( ${PYTHON_DEPS}
      $(python_gen_any_dep 'dev-python/jinja2[${PYTHON_USEDEP}]') )"

  pkg_setup() { python-any-r1_pkg_setup; }

  python_check_deps() {
      use dbus && python_has_version "dev-python/jinja2[${PYTHON_USEDEP}]"
  }
  ```

  `python_check_deps()` is the load-bearing part: `python_setup` calls it per
  impl (via `_python_run_check_deps`, with `PYTHON_USEDEP` exported) and
  falls back down the impl list until one actually has the module. Without
  this override the default returns success and the newest impl is chosen
  blind — the failure only shows up in a real `emerge`, because direct
  `ebuild <file> clean …` phase walks skip `pkg_setup`.
- Verify after fixing: build log shows `Checking whether python3_X is
  suitable …` lines per impl and `Found PY_<module>` (cmake
  `find_python_module`), and no `pip install` / `venv` rule executing in
  `build.ninja`. A command-less `build <name>: phony` venv target left in
  build.ninja is a harmless leftover.

## Resolver gotchas

- `USE=foo emerge …` applies `foo` to **every** package in the graph (surprise
  REQUIRED_USE like `imagemagick test? corefonts`). Scope per-package via
  `package.use` instead. `USE` is space-separated — `USE=a,b` is invalid.
- No write access to `/etc/portage` (uid≠0)? Do scoped pretend checks with a
  throwaway `PORTAGE_CONFIGROOT=/tmp/pcfg` containing `repos.conf` (real repo
  locations), a `make.profile` symlink, and `package.use/…`.
- The live overlay may be registered under an unexpected repo id — check
  `cat /etc/portage/repos.conf/*.conf` (here `[local]` → the git tree itself)
  and `portageq get_repo_path / <id>`.
- An already-installed version satisfying a *loose* constraint never upgrades
  on re-emerge. If the code provably needs newer (upstream `uv.lock` can pin
  newer than the pyproject specifier implies), floor the RDEPEND version.

## The loop (any repo/overlay)

1. Write/edit the ebuild; base it on the closest similar ebuild in
   `/usr/portage/<cat>/<pn>/`.
2. Update the Manifest after every add/edit: `pkgdev manifest` (or
   `ebuild <file> digest`). Without it, Portage ignores the new ebuild or
   fetches fail digest verification.
   - Exception: in `~/repos/slonko` always use `ebuild <file> digest` —
     that repo is kept digest-synced by hand; don't assume other overlays
     work the same way.
3. Static check: `pkgcheck scan` in the package dir.
4. Phase walk (non-destructive): `ebuild ./<pn>-<pv>.ebuild clean unpack`
   then `prepare configure compile test install` — stop where it breaks.
   - Always start with `clean` (i.e. `ebuild <file> clean <phase>`), or at
     minimum after ANY ebuild edit: Portage restores the saved
     `<workdir>/temp/environment` from the previous phase run and will
     silently keep the OLD `IUSE`/flags/variables — edits look ignored.
     Deleting `<workdir>/temp/environment` + the `.installed` marker is the
     cheap alternative, but `clean` is the reliable default.
   - A failed install leaves partial files in `<workdir>/image/`; `rm -rf`
     that image dir (or run `clean`) before retrying install.
   - Bare non-root `ebuild` runs fail `dobin`/`newbin` with
     `install: cannot change ownership ... Operation not permitted`
     (helper runs `install -o ${PORTAGE_INST_UID:-0} -g ...`). Real `emerge`
     sets these itself; for direct `ebuild` testing use
     `PORTAGE_INST_UID=$(id -u) PORTAGE_INST_GID=$(id -g)` and `USE=...`
     env overrides.
5. Real install test: `emerge -11 =<cat>/<pn>-<pv>` (exercises the resolver,
   USE flags, and dep graph, unlike the raw `ebuild` command).
6. Version bump: copy old→new ebuild, fix `SRC_URI`/checksums, drop `files/`
   patches that upstream merged, digest, `pkgcheck scan`, `emerge` test.

## Fixing a broken ebuild (install failure)

Reproduce, locate the failing phase, classify, fix the root cause, re-run
from the failed phase. The failure category is usually obvious from where
emerge stops.

1. **Get the log.** Console output tells you the phase; details:
   `tail -n 200 /var/tmp/portage/<cat>/<pn>-<pv>/temp/build.log` — search the
   LAST error before the `>>> ` die line, not the first warning. Also check
   `.../temp/` for `meson-logs/`, `cmake-logs/`, `*.log` side files; to jump
   straight to the last error: `tac <pkg>/temp/build.log | grep -im1 -B2 -A8
   error`.
2. **Re-run cheaply.** Portage keeps the failed work dir until the next build
   of that package (`FEATURES=keepwork` keeps it after success too). Iterate
   without the resolver: `ebuild <file> clean prepare configure compile`
   walks phases from unpack; the tree under `.../work/` is still there to
   inspect and run `make` in by hand. After the fix:
   `emerge -1 --resume` retries just what failed.

Failure categories and canonical fixes:

| Symptom (phase) | Root cause | Fix |
|---|---|---|
| "Digest verification failed" / missing Manifest | ebuild edited without re-digest | `ebuild … digest` / `pkgdev manifest` |
| 404 on fetch (fetch) | upstream moved/retagged/renamed archive | verify the real URL (`curl -IL`), update `SRC_URI`; GitHub retag ⇒ keep name, new hash |
| Checksum mismatch on existing distfile | upstream re-released the same tarball | verify legitimacy (upstream notes) then re-digest; never "fix" by copying files around |
| "cannot find the ebuild's S" after unpack (unpack) | archive extracts to a dir that isn't `${WORKDIR}/${P}` | `ls /var/tmp/portage/.../work/`, then `S="${WORKDIR}/whatever"` (or `MY_P`) |
| Patch fails to apply (prepare) | patch already upstreamed, or context drifted | delete the patch (if `patch --dry-run -p1` fails cleanly upstream), or refresh: fix in `work/`, `diff -uN orig fixed > new.patch` into `files/`, renumber order in `PATCHES` |
| `aclocal-1.x: command not found` / stale libtool (configure) | autotools files older than toolchain | `inherit autotools` + `eautoreconf` in `src_prepare` (or `eautoconf`/`eautomake` for the specific file) |
| `unrecognized options: --build ...` (configure) | not a GNU configure script | stop using `econf`; call raw `./configure`/`make` with explicit flags — or the project is cmake/meson misdetected |
| undefined `std::*` / `__cxa_*` refs when a C project's configure probe links a static C++ lib, e.g. boringssl (`SSL_connect in -lssl... no`) | `-lstdc++` passed via LDFLAGS lands BEFORE the conftest object; GNU ld's `--as-needed` drops it (mold resolves order-independently and masks this — a host build passing under mold proves nothing) | `append-ldflags "-Wl,--push-state,--no-as-needed" "-lstdc++" "-Wl,--pop-state"`; never link plain libs via LDFLAGS otherwise |
| string macro via CPPFLAGS (`-DX="..."`) compiles as a bare number (`too many decimal points` / `expected ';' before numeric constant`) | shell quote removal strips plain quotes somewhere in the make→sh pipeline; which recipes lose them varies | backslash-escape: `append-cppflags "-DX=\\\"val\\\""` — gcc consumes `\"val\"` as a string; the `missing terminating " character` warning it prints is cosmetic |
| `-Werror` / `error: ... [-Werror=...]` on new GCC/clang (compile) | old code + newer compiler | prefer version bump or upstream patch; otherwise `inherit flag-o-matic` + `append-flags -Wno-error` **with a comment and issue link** — never blanket-strip user CFLAGS |
| Missing header/lib (`fatal error: foo.h`) (compile) | omitted dependency | add to `DEPEND`/`BDEPEND` (check `pkg-config --exists`, or upstream docs' build requirements) |
| `-fcommon` multiple-definition link error on gcc10+ | pre-C17 tentative defs | `append-flags -fcommon` with comment (upstream fix = bump) |
| Fails only with `-jN` (compile) | serial-make bug | reproduce with `MAKEOPTS="-j1" emerge …`; then `emake -j1` in `src_compile` + comment, or upstream bug report |
| Test suite fails (test) | network/root/chronic-flake/needs-service | first confirm it's not a real bug (check upstream issue tracker); then deselect (`EPYTEST_DESELECT`, meson/cmake test excludes) or `RESTRICT="test"` + comment. `network-sandbox` failures are the sandbox doing its job |
| `unrecognized arguments: --cov …` (test) | pyproject addopts need a plugin not in `EPYTEST_PLUGINS` (no stripping once plugins are set explicitly) | `sed -i -e '/--cov/d' pyproject.toml` in `src_prepare` (pymemcache pattern) or add the plugin |
| `ImportError: attempted relative import with no known parent package` / `cannot import name X from 'tests' (unknown location)` (test) | PyPI sdist omits `tests/__init__.py`/helpers that the git repo has (MANIFEST.in bug) | compare sdist vs git tree; switch SRC_URI to the GitHub tarball (convertdate pattern), `S` = repo dir name |
| `'flaky' not found in \`markers\` configuration option` (test) | strict markers + mark registered by an unloaded plugin (e.g. pytest-rerunfailures) | grep for the mark, add the registering plugin to `EPYTEST_PLUGINS` |
| `ImportError while loading conftest …` optional dep (test) | conftest.py imports an unpackaged dep at collection; **`--ignore` does not prevent conftest imports** | `rm -rf` that tests dir in `src_prepare` (wrapt pattern) or ship the dep in TEST BDEPEND |
| `pip install` / `Failed to resolve 'pypi.org'` during compile (venv fallback) | build-time python module missing for the impl python_setup picked — any-r1 without `python_check_deps()` override | add `python_check_deps()` + `python_gen_any_dep` (see "Build-time-only python" above) |
| `PermissionError` reading `/etc/*.conf` or `mkdir /var/lib/…` during settings import (test) | package reads/makes runtime config dirs as the build user; stale root-owned conf from an earlier merge | pre-set env overrides in `src_test` (`load_dotenv` `override=False`), point config at an in-tree file, redirect dirs into `${T}` |
| QA Notice: files left in S / not in image dir (install) | files built but never moved to `${D}` | replace `cp`/`mv` with `dosym/doins/doexe` (or use eclass `*_src_install`) |
| Sandbox violation (access to /foo denied) (install) | phase writes outside `${D}`/`${T}` | fix to use `${D}`/`${T}`; `addwrite`/`addread` are a last resort with a comment |
| `...: No such file` on `doman`/`dodoc`/`newinitd` args (install) | upstream path drift after bump | check what actually exists under `S` and fix the path |
| `pkg_postinst`/`pkg_preinst` die | broken in-ebuild logic | reproduce standalone in a shell (they're just bash); `ebuild … preinst postinst` runs them without rebuilding (needs an unmerged ebuild in `$PWD`) |
| Works under `ebuild …` but breaks under `emerge` | missing `DEPEND` (host tool) or wrong BDEPEND/RDEPEND split | emerge runs in a clean sandbox; the `ebuild` command runs in your env — trust the emerge failure, fix the dep split (`reference.md`) |
| revdep-rebuild finds broken .so after install | linked lib not in `RDEPEND`, or slot moved | add the runtime slot dep (`:=`); `equery b <file>.so` finds the owning package |

3. **Look up the answer before inventing it.** Search bugs.gentoo.org and
   GitHub `gentoo/gentoo` PRs for the package — most build failures against
   newer toolchains are already fixed somewhere; port the patch. Search how
   other ebuilds handle it:
   `grep -rl 'append-flags -Wno-error' /usr/portage/*/*/*.ebuild | head` (same
   trick for any flag/eclass). `grep -rl <pkg-name> /usr/portage/*/*/*.ebuild`
   finds reverse-dependency ebuilds that document known constraints.
4. **Prefer a version bump over patching.** If upstream released a fix,
   bump — deleting stale patches is the laziest correct repair.
5. **Verify the whole chain:** failing phase passes → full phase walk passes →
   `pkgcheck scan` silent (QA warnings are real bugs — fix, don't `RESTRICT`
   away; `RESTRICT="test"` only for genuinely broken suites, with a comment)
   → clean `emerge -11 =cat/pn-pv` succeeds → package actually runs
   (`/usr/bin/<thing> --version`).
6. Keep the evidence: comment every `-Wno-error`-style workaround in the
   ebuild with *why* + upstream/bug link, so the next maintainer (you) can
   delete it on the next bump.

## Source of truth

When this skill and `reference.md` are silent or conflict: devmanual
<https://devmanual.gentoo.org/ebuild-writing/index.html> and QA policy guide
<https://projects.gentoo.org/qa/policy-guide/>. Fetch the relevant page rather
than guessing.
