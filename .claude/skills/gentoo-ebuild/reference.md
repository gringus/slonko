# Ebuild reference (distilled from devmanual + 2026 tooling state)

Source of truth when this page is silent: devmanual
<https://devmanual.gentoo.org/ebuild-writing/>, QA policy guide
<https://projects.gentoo.org/qa/policy-guide/>, `ebuild(5)` man page, and
`/usr/portage/eclass/<name>.eclass` (eclass source — always the ground truth
for behavior).

## EAPI status (as of 2026-09)

| EAPI | Status | Key facts |
|---|---|---|
| 0–4 | obsolete (tree: banned for new ebuilds) | don't touch |
| 5, 6 | deprecated | 6: Bash 4.2, default src_prepare (PATCHES+eapply_user) & src_install, `eapply`/`eapply_user`/`einstalldocs`, `einstall` banned |
| 7 | deprecated but common in tree | `BDEPEND` split from DEPEND (CBUILD vs CHOST); `BROOT`/`SYSROOT`/`ESYSROOT`; path vars lose trailing `/`; `ver_cut`/`ver_rs`; `dolib`/`dohtml` banned; empty dep groupings = error |
| **8** | **current default — safe everywhere** | `IDEPEND`; `fetch+`/`mirror+` per-URI RESTRICT override; metadata vars (IUSE/REQUIRED_USE/*DEPEND/PROPERTIES/RESTRICT) accumulate across eclasses; PATCHES can't carry patch options (`eapply --`); econf `--datarootdir`+`--disable-static`; `useq`/`hasq`/`hasv` banned; `usev` 2-arg; pkg_* run in empty dir |
| 9 | finalized (approved 2025); use when eclasses support it | PM vars no longer exported to env (SYSROOT/ESYSROOT/BROOT/TMPDIR/HOME excepted — external tools need explicit `--root` etc.); `assert` banned → `pipestatus || die`; `domo` banned (insinto+newins); Bash 5.3 (`${ cmd; }`, `local -I`); absolute symlinks in D merged as-is; `edo`, `ver_replacing` |

Policy: newest workable EAPI; avoid newest for `@system` + its deps. EAPI-9
shim eclasses (`edo`, `eapi9-pipestatus`, `eapi9-ver`) exist for EAPI 7/8
trees. `pkgcheck` flags `DeprecatedEapi` / `NewerEAPIAvailable`.

## Skeleton (devmanual quickstart, trimmed)

```bash
# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Exuberant ctags generates tags files for quick source navigation"
HOMEPAGE="https://ctags.io/ https://github.com/universal-ctags/ctags"
SRC_URI="mirror://sourceforge/ctags/${P}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~mips ~sparc ~x86"
# empty IUSE / DEPEND / BDEPEND lines are omitted, not set to ""

src_prepare() {
	default   # runs PATCHES + eapply_user; keep via default when overriding
}

src_configure() {
	econf --with-posix-regex
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc FAQ NEWS README
}
```

USE-conditional configure: `IUSE="crypt ssl"`, deps like `ssl? ( dev-libs/openssl )`,
`econf $(use_enable nls) $(use_enable ssl) $(use_with ldap)`.
Tabs (display 4 spaces); header first two lines exactly as above; omit
variables that are empty. `|| die` not needed after Portage helpers (EAPI≥4).

## PM-set variables (read-only; never assign)

`P` `${PN}-${PV}` · `PN` `PV` `PR` (r0 if none) `PVR` (6.3-r1) `PF`
(`${PN}-${PVR}`) · `A` = distfiles after USE-filtering · `CATEGORY` ·
`FILESDIR` = `<pkg>/files` · `WORKDIR` = unpack root · `T` = temp · `HOME`
fake · `D` = image dir · `ED`/`EROOT` = `${D}${EPREFIX}`/`${ROOT}${EPREFIX}` ·
`ROOT` merge target — **only in pkg_* phases; never src_* (pkgcheck
MisplacedVariable)** · `BROOT` CBUILD-tools root (usually empty ⇒ `/`) ·
`SYSROOT`/`ESYSROOT` where DEPEND headers/libs live · `DISTDIR` · `EPREFIX`
· `MERGE_TYPE` (source/binary/buildonly) · `REPLACING_VERSIONS` /
`REPLACED_BY_VERSION` (upgrade/downgrade context in pkg_* pre/postinst).
Path vars never end in `/`. EAPI 9: not env-exported (see EAPI table).

## Ebuild-defined variables

| Var | Rules |
|---|---|
| EAPI | top, unquoted; never in eclasses |
| DESCRIPTION | mandatory, ≤80 chars, no trailing period, don't echo PN |
| HOMEPAGE | mandatory (except virtuals); space-separated URLs; literal — **no ${PN}**; HTTPS; none ⇒ `https://wiki.gentoo.org/wiki/No_homepage` |
| SRC_URI | see below; USE-conditionals; rename via `url -> ${P}.tar.gz` (spaces around `->`) |
| LICENSE | mandatory; exact ids from `/usr/portage/licenses/`; multiple ids space-sep; `use? ( ... )` allowed; bare `GPL`/`LGPL` invalid |
| SLOT | mandatory; `"0"` or real slot; never empty; subslot `0/3` (EAPI≥5) |
| KEYWORDS | space list; `arch` stable `~arch` testing `-*` all-testing; never `*`/`~*`; `""` = needs package.accept_keywords (`**/cat/pn`) — normal for live/overlay-only |
| IUSE | every flag referenced anywhere incl. in REQUIRED_USE/eclass adds (don't redeclare inherited ones); omit if empty |
| REQUIRED_USE | DEPEND-syntax constraints; operators below |
| PROPERTIES | `interactive` `live` `test_network`; USE-conditional ok |
| RESTRICT | `fetch` `mirror` `strip` `test` `userpriv` `bindist`; use per-URI `fetch+`/`mirror+` (EAPI 8) instead of blanket |
| DEPEND / BDEPEND / RDEPEND / PDEPEND / IDEPEND | class table below |
| S | default `${WORKDIR}/${P}` — set only when different (e.g. `S="${WORKDIR}/${MY_P}"`) |
| DOCS / HTML_DOCS | default `einstalldocs` inputs |
| PATCHES | array of patches applied by default src_prepare |

Reserved for the PM (don't use): names starting `__`, `abort`, `dyn`, `prep`;
containing `ebuild`/`hook`/`portage` (except EBUILD_PHASE*).
Good constants: `${P}` `${PV}` `MY_P` in SRC_URI/S/`--docdir=${PF}`; bad:
`${PN}` inside HOMEPAGE/EGIT_REPO_URI/URL domains.

### SRC_URI details
- USE-conditional: `x86? ( https://.../${P}-sse.tar.bz2 )`.
- Rename `-> ${P}.tar.gz` controls distfile/mirror name — always use for
  GitHub archive URLs (`.../archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz`).
- `mirror://<group>/...` only for multi-location / mirror-network upstreams
  or fetch-restricted fallbacks; otherwise the primary HTTPS URL.
- Big patches/distfiles too big for `files/`: devspace upload to
  dev.gentoo.org, add via `SRC_URI="..."` continuation.
- All network at fetch time — no downloads inside src_* phases (breaks
  `--fetchonly`; live ebuilds exempt).

## Dependency classes

| | BDEPEND | IDEPEND | DEPEND | RDEPEND | PDEPEND |
|---|---|---|---|---|---|
| Present at | build | merge/install-time | build | install+runtime | post-merge |
| Built for | CBUILD | CBUILD→BROOT | CHOST | CHOST | — |
| Root (unprefixed) | `/` | SYSROOT | ROOT | ROOT | — |
| `has_version` flag | `-b` | `-d` | `-r` | `-r` | — |

- `PDEPEND` only to break RDEPEND cycles. Don't list implicit system deps
  (toolchain, virtual/libc). Never depend on metapackages.
- Slot syntax: `:0` exact slot (ignores subslot); `:0/3` pins slot+subslot
  (no `=`; `:slot/sub=` is invalid); `:*` any slot, no subslot rebuild;
  `:=` any slot + rebuild when the dep's slot/subslot changes (use for
  linked libs); `:slot=` = exact slot + subslot rebuild.
- `|| ( a b )` alternatives — EAPI 7+: empty grouping / unconditionally-false
  member = error. USE deps: `flag? ( cat/pkg )`. One atom per line.
- Version atoms: `>=cat/pkg-2`, `=cat/pkg-1.2*`; GTK1 is `=x11-libs/gtk+-1.2*`.
- Accumulation: IUSE/REQUIRED_USE/*DEPEND/PROPERTIES/RESTRICT accumulate
  across eclasses since EAPI 8 (`+=` not needed); EAPI/HOMEPAGE/SRC_URI/
  LICENSE/KEYWORDS do not.

## USE-conditional code patterns

| Call | flag set | flag unset |
|---|---|---|
| `$(use_enable nls)` | `--enable-nls` | `--disable-nls` |
| `$(use_enable crypt gpgme)` | `--enable-gpgme` | `--disable-gpgme` |
| `$(use_enable !flag)` | (flag off ⇒ enable) | … |
| `$(use_with ipv6)` / `$(use_with X x)` | `--with-ipv6` / `--with-x` | `--without-*` |
| `usex f y n` | `y` | `n` |
| `usev f` / 2-arg `usev f true` (EAPI≥8) | `f` / `true` | empty |
| `$(usev foo --enable-foo)` | `--enable-foo` | empty (build sys with only --enable switch) |

`useq`/`hasq`/`hasv` banned since EAPI 8 — `use`/`has` + `usev`.
REQUIRED_USE operators: `|| ( a b c )` ≥one; `^^ ( )` exactly one;
`?? ( )` ≤one; nesting `foo? ( || ( bar baz ) )`; `foo? ( !bar )` mutual
exclusion. Check the conflicting-USE policy page before adding conflicts —
some belong in `package.use.mask` instead.

## Phase functions

Order (source install): `pkg_pretend → pkg_setup → src_unpack → src_prepare →
src_configure → src_compile → src_test (if FEATURES=test) → src_install →
pkg_preinst → [D→ROOT merge] → pkg_postinst`. Binary install skips src_*.
Unmerge: `pkg_prerm → pkg_postrm`. `pkg_pretend` has no env propagation / dep
guarantees — checks only. Define phases in call order.

| Phase | EAPI-8 default | Override only if… |
|---|---|---|
| src_unpack | `unpack ${A}` | nonstandard archives (use `unpacker.eclass` for .7z/.lha/.rar — unpack dropped them in EAPI 8) |
| src_prepare | `eapply -- "${PATCHES[@]}"` then `eapply_user` | extra patching/sed — **must still call `eapply_user`** (directly or via `default`) |
| src_configure | `econf` | extra switches |
| src_compile | `emake` | custom build |
| src_test | `emake check` (parallel ≥5) | nonstandard tests |
| src_install | `emake DESTDIR="${D}" install` if Makefile + `einstalldocs` | manual installs |

`default` = phase-specific default. `einstall` banned since EAPI 6 —
`emake DESTDIR="${D}" install`.

## Patching (eapply)

Tarball patches preferred over modified tarballs. Preferred: global
`PATCHES=( "${FILESDIR}"/${P}-foo.patch )` + default src_prepare. `eapply`
(EAPI≥6): files or dirs (dir = *.patch/*.diff in POSIX order, no recursion,
error if empty); default `-p1`; GNU `patch` options before paths; `--` ends
options; auto-dies. Non-p1: `eapply -p0 "${FILESDIR}"/${PV}-foo.patch`.
**EAPI 8: PATCHES can't carry patch options** (`eapply -- "${PATCHES[@]}"` is
the default) — call eapply manually or rebase the patch. Large patches:
devspace via SRC_URI, then `eapply "${WORKDIR}/dir"`.

## econf / emake / flags

`econf` = configure wrapper; always use (correct Gentoo paths): passes
`--prefix=/usr --mandir=/usr/share/man --infodir --datadir=/usr/share
--sysconfdir=/etc --localstatedir=/var/lib --host=${CHOST} --libdir
(from LIBDIR_ABI) --disable-dependency-tracking --disable-silent-rules
--docdir=/usr/share/doc/${PF} --htmldir [--with-sysroot EAPI≥7]
--datarootdir --disable-static (EAPI 8)`. **Never let configure auto-detect
optional features** (USE="-perl" users must not get perl linked): force
`--enable-*/--disable-*/--with-*/--without-*` and test the switches.

`emake` = make wrapper (applies MAKEOPTS); always; any target
(`emake extras`). Keep parallelism — patch serial makefiles;
`emake -j1` last resort only. Verbose: autotools `V=1` (econf already
`--disable-silent-rules`), cmake `cmake_src_compile`/`VERBOSE=1`, Go
`GOFLAGS="-x"`. Toolchain: `tc-getCC`/`tc-getCXX`/`tc-getPKG_CONFIG` from
`toolchain-funcs` — **`${CC}`/`${CXX}` are NOT correct**; bad Makefiles:
`emake CC="$(tc-getCC)" CFLAGS="${CFLAGS}" ...`; prefer making the build
*use* the vars over sed-substituting values. `flag-o-matic`:
`replace-flags`/`append-flags`. Respect CC/CXX/…/LDFLAGS (LDFLAGS goes to the
compiler driver, not ld directly); AR/AS/NM/RANLIB/LD/LEX/YACC only where the
build invokes them.

## Common mistakes (devmanual catalogue, condensed — all cost real bugs)

1. Unguarded external calls → `cmd || die` (EAPI 9: `pipestatus || die`).
2. `static` = statically-linked *binaries*; installing static libs ⇒ `static-libs`.
3. `ROOT`/`ED` in `src_*` → pkgcheck MisplacedVariable; build-time files come
   from `/`/SYSROOT.
4. Don't echo doc paths with extensions (`INSTALL.gz`) — compression varies;
   say "the INSTALL file in /usr/share/doc/${PF}".
5. Non-verbose builds hide ignored flags → fix verbosity (see econf/emake
   above); unfixable: file a bug.
6. `-Werror` must go (new compilers kill builds): remove in build files or
   `append-flags -Wno-error`; verify in log; specific `-Werror=xyz` may stay.
7. Header not exactly skel.ebuild's first two lines.
8. Never redefine `P/PV/PN/PF` → `MY_P`/`MY_PN`/`MY_PV` + bash expansion.
9. Hardcoded versions in SRC_URI/S break bumps → `${PV}`/`${P}`; mismatched
   tarball names: `MY_P=${P/pyopenal/PyOpenAL}` + `S=${WORKDIR}/${MY_P}`;
   `ver_rs`/`ver_cut` over sed/awk/cut.
10. DEPEND syntax: always `cat/pkg`; no trailing `*` after `>=`; one dep per
    line; no metapackage deps.
11. Incomplete deps: check configure.ac / *.spec / README; pkg-config/
    intltool/libtool/doxygen/gettext → BDEPEND.
12. Invalid LICENSE ids (GPL→GPL-2+); check COPYING; novel license ⇒ new
    file in licenses/.
13. KEYWORDS lies: new ebuilds `~arch`; on bumps demote stable → `~arch`.
14. Dead IUSE flags / obsolete inherits (eutils!) — prune.
15. Missing SLOT (`SLOT="0"` mandatory).
16. DESCRIPTION/HOMEPAGE bad (purpose sentence; no PN echo; test HTTPS).
17. Tabs not spaces. 18. Trailing whitespace (`pkgcheck`).
19. Redundant `S=${WORKDIR}/${P}`. 20. Docs not installed (`dodoc`;
    `doc` USE for big/dep-heavy docs). 21. Broken USE flags unmasked ⇒ mask
    in profiles/base/package.use.mask when hitting stable. 22. Old EAPI.
    23. Direct `pkg-config` → `$(tc-getPKG_CONFIG)` + `virtual/pkgconfig`
    in BDEPEND.

## Versions, revisions, slots

- Upstream name/version mismatch ⇒ `MY_PN`/`MY_PV`/`MY_P`
  (`MY_PV=$(ver_rs 2 '-')`). `ver_cut 1` major, `ver_cut 2-` rest;
  `ver_rs [range] char|''`; `ver_test` (EAPI≥7). No sed/awk/cut on versions.
- Suffix order: `_alpha < _beta < _pre < _rc < plain < _pN`
  (1.0_p1 > 1.0_rc2 > 1.0). `-rN` filename revision (PR=r0, PVR, PF).
- SLOT: mandatory; sub-slot `SLOT="0/3"` (EAPI≥5): consumers with `:=`/
  `:slot=` rebuild on subslot change; document in metadata.xml
  `<slots>/<subslots>`.
- QA_* vars (QA_PREBUILT, QA_TEXTRELS, QA_FLAGS_IGNORED, …) = last-resort
  QA suppression for closed binaries; only with QA-team agreement.

## Eclasses

`inherit a b c` at the very top (before anything that uses eclass vars),
args alphabetical (except when phase-override order matters, e.g.
multilib-minimal last); **no conditional inherit**; eclasses never set EAPI;
EAPI≥8 metadata vars accumulate automatically (no `+=`).

High-traffic (read `/usr/portage/eclass/<name>.eclass` for truth):
`autotools` (econf/emake/eautoreconf), `cmake` (`mycmakeargs` array),
`meson` (`emymesonargs`), `distutils-r1` (+`pypi` — `PYPI_MODULE_NAME`;
python: `PYTHON_COMPAT`, `DISTUTILS_SINGLE_IMPL`, `distutils_enable_tests
pytest`, `EPYTEST_DESELECT`, `python_gen_cond_dep`), `cargo`
(vendored `CRATES`, live via cargo-crate / `cargo.eclass`), `rust`
(EAPI-8 unified eclass vs slotted rust; `RUST_OPTIONAL`; newer than
cargo-r1), `go-module` (mature EAPI 7–9; `GO_OPTIONAL`,
`go-module_live_vendor`; non-vendored ⇒ `-deps.tar.xz` from
gentoo-golang-dist), `git-r3` (`EGIT_REPO_URI`, `EGIT_BRANCH`, `EGIT_COMMIT`,
`EGIT_SUBMODULES`), `toolchain-funcs`, `flag-o-matic`, `systemd`
(`systemd_dounit`/`systemd_newunit`/`systemd_enable_service`), `tmpfiles`,
`desktop`+`xdg` (`domenu`, .desktop validation), `bash-completion-r1`
(`dobashcomp`), `acct-user`/`acct-group` (`ACCT_USER_ID=-1` auto,
`ACCT_USER_GROUPS`, `acct-user_add_deps`; pkgcheck flags acct IDs `-1`
static via InvalidAccountIdentifier), `multilib`/`multilib-minimal`
(`ABI_*`), `perl-module`, `ruby-single`/`ruby-fakegem`, `java-pkg*`,
`edo`/`eapi9-pipestatus`/`eapi9-ver` (EAPI-9 shims), `branding` (Gentoo
OS branding vars).

## metadata.xml (GLEP 68)

Every package must have one; skeleton `skel.metadata.xml`, generator
`app-portage/metagen`; validate `xmllint --noout --valid metadata.xml` before
commit. Root `<pkgmetadata>`; children: `<maintainer type="person|project">`
(email required; `<name>`, `<description>` optional; `restrict="&gt;=cat/pkg-2"`
splits by version; **first maintainer = bug assignee**; maintainer-needed =
zero maintainer tags + `<!-- maintainer-needed -->`), `<longdescription
lang="en">` (required English; `<pkg>`/`<cat>` refs inside),
`<stabilize-allarches/>`, `<slots><slot name=...><subslots/></slot></slots>`,
`<use><flag name="x">description</flag></use>` (local flags only; `<pkg>`
refs allowed), `<upstream>` once: `<changelog>` (version-independent),
`<doc lang="en">`, `<bugs-to>` (URL or mailto), `<maintainer
status="active|inactive">` (no type attr), **`<remote-id
type="github">owner/repo</remote-id>`** (pkgcheck `MissingRemoteId` reads
this; today's machine-readable bump hint).

## 2026 tooling

- **pkgdev** (0.2.18): `manifest` (`-m` checks Gentoo mirrors first),
  `commit` (auto msg + header mangler: copyright years, KEYWORDS sort,
  optional pkgcheck gate), `push` (pkgcheck --commits before git push),
  `mask` (last-rite/PMASKED + bug refs), `bugs` (STABLEREQ/KEYWORDREQ),
  `showkw`, `tatt`. **No `pkgdev bump`** — metadata-bump tooling retired;
  bump = manual `cp` + `pkgdev manifest`. (The old GitHubPopulate/
  CURRENT_BUMPSTRIP eclass pattern is overlay-era, not tree tooling.)
- **pkgcheck** (0.10.4x): checks worth knowing — `DeprecatedEapi`,
  `NewerEAPIAvailable`, `UnstatedIuse`, `MisplacedVariable` (ROOT in src_*),
  `MissingRemoteId`/`InvalidRemoteID`, `VariableOrderWrong`,
  `DescriptionCheck` (no trailing period), `DeadEclass`,
  `CommandSubstitutionCheck` (EAPI-9 `${ cmd; }` suggestion),
  `MakeDefaultsUnquoted`, `NonArrayPatches`/`SwitchInPatches`,
  `CrossSlotRangeDep`, `RequiredUseUnsatisfiable`, `RedundantPypiPN`,
  `PythonPackageNameCheck` (lowercase-hyphen PyPI), `TooManyCrates`,
  `EclassManualDepsCheck` (rust eclass). Landlock-sandboxed scans; `--net`
  for network checks. `pkgcheck scan --commits` in CI.
- GitHub release SRC_URI convention:
  `SRC_URI="https://github.com/OWNER/REPO/archive/v${PV}.tar.gz -> ${P}.tar.gz"`
  + `<remote-id type="github">` in metadata.xml as the bump identity.
- Gentoo migrating GitHub→Codeberg (mirror codeberg.org/gentoo/gentoo);
  GitHub PR flow still canonical for contributions for now.
