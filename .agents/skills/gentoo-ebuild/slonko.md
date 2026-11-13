# slonko overlay conventions

Rules specific to the slonko overlay (`~/repos/slonko`). Generic ebuild
knowledge lives in SKILL.md + reference.md (+ language files) — this
file only covers what differs here.

**NEVER put `#` comments inside a quoted dependency string** (SRC_URI,
BDEPEND, RDEPEND, …) — they parse as atoms (`Invalid atom (#)`), the
digest fails or leaves a stale Manifest, and the error is easy to miss in
truncated output. Comments go above the assignment. Hit three times in
one session (2026-11-09) — check before every digest. Same for scripted
edits (python/sed): `str.replace` no-ops silently on a mismatched target —
grep for the expected marker after every batch rewrite (embeddings-ollama
2026-11-09: ebuild shipped without its test phase for a whole run).

## Manifest / digests

- Always `ebuild <file> digest` (not `pkgdev manifest`) — this repo is
  kept digest-synced by hand. `metadata/md5-cache/` is regenerated
  alongside but stays **untracked** — never commit it.

## Before bumping an overlay package

- Check whether `::gentoo` has caught up first (`eix -e <pn>` or the
  tree). If the tree now has an equal/newer version and our ebuild
  carries no real delta (patches/USE/logic), surface that instead of
  bumping — dropping the package is the user's call. If we diverge
  deliberately, diff against the tree's ebuild to see the delta before
  rebasing it on the new version.

## Package preferences

- Go packages: prefer `EGO_SUM` over dependency/vendor tarballs — no
  extra distfile to host or regenerate per bump (details + wiring in
  `go.md`). The deprecation QA notice is accepted until it turns
  fatal.
- Rolling distfile URLs (raw.githubusercontent branch paths, etc.) get
  pinned to the immutable commit serving the hashed content — the
  Manifest then stays valid forever; verified pattern in
  `nltk-data` (`NLTK_DATA_COMMIT`) and `llama-index-core` src_test.
  No self-hosting: public upstream URLs are the convention.

## Tests

- **Default: every ebuild runs its test suite**, unless upstream does not
  provide one. Only skip a test phase entirely when the suite genuinely
  cannot run (needs unpackaged deps, a live service we don't package, or
  collects junk like `examples/`) — and then no `RESTRICT`, just no test
  USE flag plus a comment stating the reason (see
  `no-hand-written-restrict` memory).
- **Test-dep policy (Marcin)**: if a module a test needs is already in the
  tree, add it to the test deps — no discussion. If it is missing from the
  tree, weigh whether a new dependency is worth the extra tests before
  packaging it (e.g. `tree_sitter_language_pack` was skipped; `pandas`,
  `beautifulsoup4`, `websockets` were added). Skips whose real blocker is
  *data* (spacy models) or a second unpackaged gate (unstructured+lxml)
  stand even when one of the named modules is in-tree.
- **Exception: non-python packages with a custom test phase** get
  `IUSE="… test"` + `RESTRICT="!test? ( test )"` written by hand — no eclass
  does it for them, and without it `FEATURES=test` + `USE=-test` runs
  src_test without its deps installed. House pattern: zxing-cpp, sqlite-vec.
- PyPI sdists often omit tests: check the upstream repo and switch
  `SRC_URI` to a tag tarball if that brings the suite (tinytag pattern —
  keep `S` aligned with the archive layout; mind the tag naming, e.g.
  `2.3.2` without `v`).
- Mechanics:
  - **`EPYTEST_PLUGINS` must always be defined** in python ebuilds with
    tests — `( )` when the suite needs no plugins (strict mode: no
    container-junk autoload, cov args still stripped). `EPYTEST_XDIST=1`
    does not count (it force-loads xdist but leaves autoload on). Set
    only plugins the suite actually uses — grep the upstream sdist's
    tests, not the overlay. pkgcheck flags missing ones on pytest suites
    (`EPyTestPluginsSuggestion`, Info; not for `unittest` runners).
  - `EPYTEST_PLUGINS=( ... )` before `distutils_enable_tests` auto-adds
    the plugin deps — but **any `BDEPEND=` assignment must come BEFORE
    `distutils_enable_tests`**, or it wipes the auto-added pytest +
    plugin deps and the RDEPEND copy (banks-2.5.1 bug, 2026-11-07).
    Explicit BDEPEND entries are only for non-plugin test deps (redis,
    regex, jsonschema, git, ...).
  - `EPYTEST_IGNORE`/`EPYTEST_DESELECT` live in **global scope** (simple,
    visible next to the other test config; validated on
    sentence-transformers-6.2.0). Quote entries containing `[]` so bash
    never glob-expands them against the working directory.
    Parallelism via `EPYTEST_XDIST=1` (global; auto-adds the xdist dep
    and `-n <MAKEOPTS jobs> --dist=worksteal` at epytest time).
  - Test-only distfiles (model/encoder files): fetch them in
    `SRC_URI="... test? ( ... )"` and pre-seed the relevant cache via
    `eclass/slonko-test.eclass`: `slonko_test_seed_tiktoken_cache <dir>`
    (stdin: url|distfile pairs, exports TIKTOKEN_CACHE_DIR) and
    `slonko_test_seed_hf_repo <cache_dir> <repo> <rev>` (stdin:
    distfile|path pairs; layout goes directly inside <cache_dir> — for
    llama-index wrappers that is LLAMA_INDEX_CACHE_DIR, not
    HF_HUB_CACHE). Seed once in `src_test()`, not per-impl in
    `python_test()`.
  - Tests needing a local service: `slonko_test_spawn_server <port>
    <logfile> <cmd...>` + `slonko_test_stop_server` (waits for the port,
    death hook kills on die). The mock ollama API server for the
    llama-index ollama suites is `slonko_test_write_ollama_mock <dest>`
    (one superset file: /api/tags+show+chat+embed).
  - Per-test exclusions: `EPYTEST_IGNORE`/`EPYTEST_DESELECT` with a
    per-entry comment (test-client-imports-ollama style).
  - hypothesis ≥6.1xx injects string constants harvested from the tested
    package's source into `st.text()` — if the package's own source defines
    strings its encoder rejects (tiktoken: special tokens in
    `openai_public.py`), the given-based tests fail deterministically with a
    *different* string each run. Fix the test semantics with a small
    `src_prepare` sed (tiktoken: `disallowed_special=()`), not deselects.
- ebuildtester gotchas: `FEATURES=test` applies only to the requested
  atoms — dep test phases are skipped there (that's normal, don't read
  it as "no tests"); a bare `ebuild ... clean test` does NOT install
  the `test?` BDEPEND — `emerge` the deps first or run via
  `emerge -1`/ebuildtester.

## Repository identity

- Registered under repo id `[local]` (→ this git tree). Verify with
  `cat /etc/portage/repos.conf/*.conf` and
  `portageq get_repo_path / <id>`.
- `profiles/repo_name` must never be updated or committed: the public
  GitHub repo carries `slonko`, this local development checkout
  carries `local` (matching its id in repos.conf). Portage errors when
  repo_name doesn't match the registered repository, and there is no
  good way to serve both roles (development + normal use) from one
  checkout — so the file always stays as-is.

## metadata.xml

- Maintainer must be Marcin; keep the `<upstream>` section (bugs-to /
  remote-id / doc) per overlay convention.

## Cleanup during bumps

- "Clean up" = temporary/scratch files only. Never delete old ebuilds
  or `files/` patches unless explicitly asked.

## Session constraints

- Build/test only: no `emerge` installs into the live system, no
  `/etc/portage` edits (use throwaway `PORTAGE_CONFIGROOT` for scoped
  pretend checks instead).
