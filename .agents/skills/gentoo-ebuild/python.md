# Python ebuilds

Distilled from the Gentoo Python Guide
<https://projects.gentoo.org/python/guide/>. General ebuild rules:
`reference.md`. Overlay-specific rules: `slonko.md`. Per-version porting
notes: <https://projects.gentoo.org/python/guide/porting.html>.

## Eclass choice (decide first)

Python used **only at build time** (codegen, translators, doc builds) →
`python-any-r1`. Exception: calling a self-contained external tool
(e.g. `dev-util/meson`) needs no eclass at all; anything that loads
package-provided Python code (e.g. SCons) does.

Runtime use of Python:

| Package shape | Eclass |
|---|---|
| Python modules; setup.py or PEP 517 build | `distutils-r1` (default; `DISTUTILS_SINGLE_IMPL=1` for single-impl) |
| Scripts/bindings inside a C build system (autotools/cmake/meson) | `python-single-r1` |
| Multi-impl modules without a Python build system | `python-r1` (expert — avoid) |

- Single-impl: user picks one impl (`PYTHON_SINGLE_TARGET`); reverse
  deps must also be single-impl. Multi-impl: per-impl installs
  (`PYTHON_TARGETS`), revdeps may use any subset.
- Rule of thumb: pick the eclass that makes the ebuild simplest.
  distutils-r1 over python-r1 for multi-impl; python-single-r1 can be
  simpler than distutils-r1 for single-impl scripts-only packages.
- No build system but want eclass tests/venv → `distutils-r1` with
  `DISTUTILS_USE_PEP517=no`.
- When converting an existing ebuild: do NOT keep python deps in
  RDEPEND "because the old ebuild did" — verify runtime use first
  (check the installed file list for `.py` files; cmake codegen
  macros running jinja templates are build-time only).

Build-time python with module deps (cmake codegen etc.) — the
`python_check_deps()` trap: see its own section below.

## Build-time python with module deps (the any-r1 trap)

`python-any-r1`'s `python_setup` picks the newest installed impl from
PYTHON_COMPAT — it does NOT know which impl has the build-time python
modules (jinja2, mako, …) installed. Upstream build systems (e.g.
cmake `find_python_module`) silently fall back to `python -m venv` +
`pip install` when the import fails, which the network sandbox blocks
(`Could not find a version that satisfies the requirement`). Required
three-part pattern:

```bash
BDEPEND="dbus? ( ${PYTHON_DEPS}
    $(python_gen_any_dep 'dev-python/jinja2[${PYTHON_USEDEP}]') )"

pkg_setup() { python-any-r1_pkg_setup; }

python_check_deps() {
    use dbus && python_has_version "dev-python/jinja2[${PYTHON_USEDEP}]"
}
```

`python_check_deps()` is load-bearing: `python_setup` calls it per
impl (with `PYTHON_USEDEP` exported) and walks down the impl list
until one has the module. Without the override the default returns
success and the newest impl is chosen blind — the failure only shows
in a real `emerge` (direct `ebuild` phase walks skip pkg_setup). Also
applies when the system has a newer impl than PYTHON_COMPAT lists.
Verify the fix: build log shows per-impl "Checking whether python3_X
is suitable" lines and `Found PY_<module>`, and no pip/venv rule
executing in build.ninja (a command-less `build <name>: phony` venv
target left behind is harmless).

## Common boilerplate

`PYTHON_COMPAT` before inherit; copy the current set from a similar
tree ebuild. Values: `pythonX_Y`, `pythonX_Yt` (freethreading),
`pypy3`, `pypy3_11`.

Non-distutils eclasses make *you* wire metadata (distutils-r1 does it
automatically):

```bash
# python-single-r1 / python-r1, unconditional Python:
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
RDEPEND="${PYTHON_DEPS}"
BDEPEND="${RDEPEND}"

# python-any-r1 (build-time only):
BDEPEND="${PYTHON_DEPS}"
```

- Conditional Python (`use python`): wrap deps/REQUIRED_USE in the
  flag and `pkg_setup() { use python && python-single-r1_pkg_setup; }`.
  The pkg_setup condition must match REQUIRED_USE, which must be a
  superset of dep conditions.
- Hybrid build-time + conditional runtime (common: build scripts
  unconditional, bindings conditional): `BDEPEND=${PYTHON_DEPS}`
  unconditional, `RDEPEND="python? ( ${PYTHON_DEPS} )"`.

Environment: `${EPYTHON}` (basename — use to spawn interpreters) vs
`${PYTHON}` (absolute path — shebangs only). A full path bypasses the
distutils-r1 PEP 517 venv and imports the wrong modules.

## Dependencies on Python packages

- Imported by installed code → `RDEPEND`. Imported at build time too
  (tests always are) → also `BDEPEND="test? ( ${RDEPEND} )"`;
  `distutils_enable_tests` does this copy when called after RDEPEND.
- C-extension linked libs → `RDEPEND`+`DEPEND` (not BDEPEND).
  Header-providing Python packages (numpy) → possibly all three.
- Optional runtime deps: unconditional RDEPEND if cheap/important;
  else `optfeature` in pkg_postinst; USE-conditional only if rebuild
  is cheap.
- Upstream metadata lies (CI deps, over-pinned versions). Strip bogus
  entries with sed in `python_prepare_all` rather than omitting them
  silently — build systems enforce some of them.

Where upstream lists deps: PEP 621 `project.dependencies` (runtime),
`project.optional-dependencies` (extras/test/doc),
`build-system.requires` (BDEPEND), `requires-python` (PYTHON_COMPAT
floor); setuptools `install_requires` / `extras_require`; poetry
`tool.poetry.dependencies`.

### USEDEP generators

- Multi-impl dep: `$(python_gen_cond_dep
  'dev-python/foo[${PYTHON_USEDEP}]')` — single quotes; `${...}` is a
  template key substituted by the function, not bash. With other
  variables use double quotes + `\${PYTHON_USEDEP}`.
- In python-single-r1 ebuilds, single-impl deps take
  `[${PYTHON_SINGLE_USEDEP}]` directly (no gen_cond_dep); multi-impl
  deps still need gen_cond_dep.
- Impl-conditional: `$(python_gen_cond_dep '...' python3_{8..10})`;
  fnmatch wildcards `'python*'`; stdlib versions `3.8` (all impls with
  that stdlib). Stale impls are silently dropped — safe to leave.
- cffi/greenlet are in PyPy's stdlib: wrap explicit deps in
  `'python*'` (CPython only).
- Interpreter USE flags: `PYTHON_REQ_USE="sqlite"` (or `sqlite?` to
  tie to package USE) before inherit. Multi-flag/conditional combos:
  `$(python_gen_impl_dep sqlite)` in BDEPEND.

### python-any-r1 with Python deps

Replace `${PYTHON_DEPS}` with `$(python_gen_any_dep '...')` plus a
matching `python_check_deps()`. The two must match EXACTLY, and
`python_gen_any_dep` may be called **at most once** per ebuild:

```bash
BDEPEND="$(python_gen_any_dep '
    dev-python/polib[${PYTHON_USEDEP}]
    dev-python/pygobject:3[${PYTHON_USEDEP}]
')"

python_check_deps() {
    python_has_version "dev-python/polib[${PYTHON_USEDEP}]" &&
    python_has_version "dev-python/pygobject:3[${PYTHON_USEDEP}]"
}
```

- `python_has_version [-b|-d|-r] dep...` — verbose has_version wrapper;
  `-b` (BDEPEND root) is the default. One call with multiple deps = AND.
- Python needed only for tests: wrap gen_any_dep in `test? ()`,
  `pkg_setup() { use test && python-any-r1_pkg_setup; }`, and
  `use test || return 0` at the top of check_deps (mind `-d`/`-b`
  roots there).
- Multiple USE-conditional dep sets: put the `use`-conditionals inside
  the gen_any_dep template and mirror them in check_deps.
- Module deps with cmake `find_python_module` etc. — the
  check_deps-is-load-bearing trap: SKILL.md.

## distutils-r1

- `DISTUTILS_USE_PEP517=<system>` before inherit enables PEP 517 mode
  (preferred). Unset = legacy setup.py mode (avoid for new ebuilds).
  Read `pyproject.toml [build-system]`; canonical values: `setuptools`
  (also for plain setup.py — eclass picks the legacy backend),
  `flit` (flit_core), `flit_scm`, `hatchling`, `poetry` (poetry-core),
  `pdm-backend`, `pbr`, `uv-build`, `maturin`, `meson-python`,
  `scikit-build-core`, `sip`, `jupyter`. Special: `no` (no build
  system), `standalone` (package ships its own backend).
  Deprecated backends (flit.buildapi, poetry.masonry.api,
  setuptools.build_meta:__legacy__) → upstream should switch to
  flit_core / poetry-core / setuptools.build_meta.
- `DISTUTILS_EXT=1` when *.so* extensions are built (adds DEPEND on
  the impl, IUSE=debug, parallel build_ext). QA warns if missing.
- Rust extensions (setuptools-rust, maturin) + cargo eclass:
  `CARGO_OPTIONAL=1`, CRATES + `$(cargo_crate_uris ${CRATES})`,
  LICENSE += crate licenses, `QA_FLAGS_IGNORED` on the .so paths,
  `src_unpack() { cargo_src_unpack; }`. Generate the template with
  `pycargoebuild <dir-containing-Cargo.lock>`. Rust-level tests →
  `cargo_src_test` in `python_test_all`.
- Cython: always depend on dev-python/cython and regenerate —
  `rm src/foo.c || die` in src_configure (or `cython -3 foo.pyx -o
  foo.c`). Shipped C files break on newer Pythons. Run once; output is
  impl-independent.
- SCM-versioned packages from git snapshots:
  `export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}` (also flit_scm,
  hatch-vcs); pdm-backend: `export PDM_BUILD_SCM_VERSION=${PV}`.
  Verify all data files still get installed.
- Same source → multiple extensions = parallel-build race: broken .so
  with cryptic ImportErrors in *revdeps*, not a build failure. Fix:
  `python_compile() { distutils-r1_python_compile -j1; }`.

### Sub-phases

src_* phases split into per-impl `python_*` and run-once
`python_*_all`. Defaults exist for: python_prepare_all (patches +
pyproject handling), python_compile, python_install,
python_install_all. No default: python_prepare (defining it enables
in-source builds), python_configure(_all), python_test(_all),
python_compile_all. Overrides must call the eclass default explicitly
(`distutils-r1_python_prepare_all`, `distutils-r1_python_install`, …).

- Extra build args: `DISTUTILS_ARGS=( --external )` (setuptools global
  options). Per-command options (build_ext) → append an `[build_ext]`
  section to setup.cfg in src_configure. Custom commands: `esetup.py
  check`.
- Modules needed by tests but installed manually:
  `python_domodule` in `python_compile` → lands in
  `${BUILD_DIR}/install` (visible to the test venv AND merged into `${D}`
  by distutils-r1_python_install). Installing in `python_install`
  instead is fine but invisible to tests.
- `DISTUTILS_OPTIONAL=1` (python behind a USE flag on a primary
  autotools/cmake build): eclass sets nothing — wire
  REQUIRED_USE/deps yourself (add `${DISTUTILS_DEPS}` to BDEPEND),
  call `use python && distutils-r1_src_{prepare,compile,install}` in
  each phase, plus `distutils-r1_src_test` if python_test is defined.
  In this mode python_prepare_all does NOT apply patches.

### Sphinx docs

`distutils_enable_sphinx docs [deps…]` — adds doc USE + deps + install.
With autodoc or third-party extensions: pass the extra `dev-python/*`
deps as arguments (any-r1 API; impl may differ from PYTHON_TARGETS).
No autodoc/extensions: `distutils_enable_sphinx documentation
--no-autodoc` (plain sphinx dep). The eclass warns when the choice is
wrong.

## Tests

`distutils_enable_tests <runner>` — `pytest` | `unittest` |
`import-check` (import-only packages; `EPYTEST_IGNORE` for files that
are intentionally non-importable). Call it AFTER RDEPEND. Extra test
deps: `BDEPEND+=" test? ( … )"` — append, the function rewrites the var.

- Custom args: `python_test() { epytest -m 'not network'; }`.
  Env/pre-post: `src_test() { local -x COLUMNS=80; distutils-r1_src_test; }`.
  Non-distutils: `src_test() { epytest; }` (python-single-r1), or
  `python_foreach_impl` (python-r1).
- EPYTEST knobs (set before distutils_enable_tests):
  - `EPYTEST_PLUGINS` — set the minimal verified set at module scope,
    one per line. If unset, plugin autoload is OFF (`-p no:cov -p
    no:sugar …`) and addopts needing those plugins get stripped; if
    set, only the listed plugins load and **no stripping happens** —
    verify each entry by grepping the suite for its fixtures *and*
    marks (`mocker`, `httpx_mock`, `@pytest.mark.flaky` …); give
    `EPYTEST_*` entries per-entry `# why` comments. Upstream pytest
    config from `pyproject.toml` (`[tool.pytest]` /
    `[tool.pytest_env]`, pytest ≥9) is picked up automatically when
    tests run from the project root. Django
    packages need pytest-django + pytest-env loaded or their ini env
    vars never apply. Trap: `pytest-celery` squats the `celery` entry
    point and re-exports celery's own plugin (registering the celery
    marker) — `EPYTEST_PLUGINS=(celery)` is a no-op; leave plugins
    unset (autoload on) in that case.
    `EPYTEST_PLUGIN_LOAD_VIA_ENV=1` for plugins loaded in subprocesses
    (pytest-plugin test suites); `${PN}` in the list = no self-dep;
    `EPYTEST_PLUGIN_AUTOLOAD=1` re-enables autoload while keeping deps.
  - `EPYTEST_XDIST=1` — parallel tests (only if the suite is
    collision-free; strip pointless xdist deps).
  - `EPYTEST_RERUNS=5` — pytest-rerunfailures for flaky tests.
  - `: ${EPYTEST_TIMEOUT:=1800}` — pytest-timeout for hang-prone
    suites (per test, not total; pick a generous value).
  - `EPYTEST_IGNORE=( file )` — whole files, skipped without import;
    `EPYTEST_DESELECT=( 'tests/x.py::test_y[param' )` — individual
    tests. Module scope, or `local` arrays inside python_test for
    per-impl conditions.
- C extension imported from cwd instead of the build tree (top-level
  layout): `rm -rf pkgdir || die` before `epytest` in python_test
  (PEP 517 mode: sources unneeded after compile), or
  `epytest --pyargs pkg`. `cd`ing away loses pytest config discovery —
  prefer rm.
- Xvfb: `src_test() { virtx distutils-r1_src_test; }` — virtx is
  nonfatal, so add `|| die` in python_test.
- Undesirable test deps (strip, don't package): pytest-cov/`--cov`,
  flake8/pep8/pycodestyle, pytest-runner (`sed -e '/pytest-runner/d'
  setup.py`), tox.
- Optional test dep missing on some arches (rust): `has_version`-gated
  `local EPYTEST_DESELECT` in python_test, or `IUSE="test test-rust"`
  (profile-masked where no rust).
- All-network test suites: `PROPERTIES="test? ( test_network )"`,
  `RESTRICT="test"`.
- epytest forces `-Wdefault` (upstream `filterwarnings = error` is
  overridden; tests misusing `pytest.raises(Warning)` should be
  `pytest.warns`). Random missing tmp files → `epytest -o
  tmp_path_retention_policy=all`. ImportPathMismatchError → namespace
  package discovered as test dir → `epytest test` or `--ignore`.
- Fixture → plugin: `mocker`→pytest-mock, `event_loop`→pytest-asyncio
  (<2), `freezer`→pytest-freezegun, `httpbin`→pytest-httpbin,
  `loop`→pytest-aiohttp.
- `TypeError: _make_test_flaky() ... 'reruns'` → flaky plugin loaded
  instead of pytest-rerunfailures → `EPYTEST_PLUGINS=(
  pytest-rerunfailures )`.
- Packages reading system config at import (`load_dotenv('/etc/…')`)
  or mkdir-ing runtime dirs during settings import need env overrides
  in src_test: pre-set the vars (`local -x …`) — `load_dotenv` uses
  `override=False`, so pre-set env wins; redirect data paths into
  `${T}`. A stale root-owned conf from an earlier merge produces the
  same symptoms.
- Prefer upstream test deps in TEST BDEPEND over deselects when cheap
  (e.g. a package needing `django-auditlog` imports it
  unconditionally in tests though it's an optional runtime USE dep —
  install it for tests and force-enable via env).

## Helpers (python-utils-r1)

- `python_doscript`/`python_newscript` — shebang rewritten + python-exec
  wrapper (`python_scriptinto` for target dir). `python_domodule` —
  doins -r + byte-compiles (`python_moduleinto` sets target: absolute
  path or module name). `python_doexe`, `python_doheader`.
- `python_fix_shebang [-f] <file|dir>` — rewrite `python3`/`python`
  shebangs to the selected impl; on `${D}` in src_install, or in S for
  build-time scripts.
- `python_optimize [path]` — byte-compile; distutils-r1 PEP 517 mode
  does it unconditionally, otherwise call after manual installs.
- Getters: `python_get_sitedir/includedir/scriptdir/stdlib`,
  `python_get_library_path/CFLAGS/LIBS/PYTHON_CONFIG` (CPython only).
  They include EPREFIX — do NOT pass their output to *into helpers.

## QA warnings

- "modules not byte-compiled": partial opt levels / none → patch the
  build system or `python_optimize` in the ebuild. `.py` files that
  aren't Python (templates) → get them renamed upstream (`.py.tmpl`).
- "stray compiled bytecode": shipped .pyc → `rm` in src_prepare; or
  the ebuild removes .py files after byte-compilation (fix the order).
- "unexpected files top-level in site-packages": setuptools
  `find_packages()` grabbing `tests/` → upstream
  `exclude=["tests", "tests.*"]` (setup.cfg `[options.packages.find]`,
  pyproject `[tool.setuptools.packages.find]`). Poetry `include` keys
  need `format = "sdist"` per entry. Stray README/LICENSE etc. are
  acceptable to `rm` in the ebuild pending upstream fix.

## Naming & maintenance

- PyPI-published packages: PN = PEP 503-normalized PyPI name
  (`[-_.]+` → `-`, lowercase; do NOT add/remove `python-` prefixes).
  `zope.interface`→`zope-interface`, `ConfigArgParse`→`configargparse`.
  Use canonical PyPI URLs (pkgcheck scan --net flags redirects).
- Adding a new Python impl to an existing ebuild: no rev bump needed
  (new USE flags are use.stable.masked).
- Test at least the profile default targets + the next Python version;
  PyPy optional.
- Stabilization: 14-day delay, never prereleases, on major bumps wait
  for the first patch release.
- Raising PYTHON_COMPAT floors → check the porting notes for removed
  stdlib modules (bpo-43882 urlsplit, cgi, inspect.getargspec, …).
- Dep hygiene tools: `pip check` and `pip list --outdated` (per impl;
  ignore certifi false positives), `gpy-verify-deps` (gpyutils) vs
  ebuild metadata. Zero-versions in pip list = build system didn't
  detect the version (strip `tag_build` in setup.cfg).

## Source archives

- Prefer PyPI sdist **iff** it contains everything (especially tests);
  otherwise the VCS archive. Inspect with `tar -tzf` — a broken test
  suite (missing `__init__.py`/helpers the git repo has) → fetch the
  GitHub tarball instead. GitHub convention:
  `https://github.com/<o>/<r>/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz`.
- pypi eclass: sets SRC_URI and S automatically; translates Gentoo →
  PyPI versions (`_alpha`→`a`, `_beta`→`b`, `_rc`→`rc`, `_p`→`.post`).
  - `PYPI_PN=<name>` when the PyPI name differs from normalized PN
    (e.g. casing: `ImageHash`); `PYPI_NO_NORMALIZE=1` when the sdist
    filename is not PEP 625-normalized (old sdists with uppercase or
    dots — the filename is lowercased even with `PYPI_PN` alone).
    Both before inherit.
  - Non-default cases: `SRC_URI="$(pypi_sdist_url --no-normalize
    "${PN^}")"` (+ `S=${WORKDIR}/${P^}`).
  - Wheels: `SRC_URI="$(pypi_wheel_url [--unpack] …)"`; .whl is not
    auto-unpacked — `--unpack` renames to .whl.zip (add
    `BDEPEND="app-arch/unzip"`).
  - pypi does not merge with ebuild SRC_URI — use `SRC_URI+=`.
