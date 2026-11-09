# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )
inherit python-r1 toolchain-funcs

DESCRIPTION="Vector search for SQLite"
HOMEPAGE="https://github.com/asg017/sqlite-vec"
SRC_URI="https://github.com/asg017/sqlite-vec/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="Apache-2.0 MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="python test"
RESTRICT="!test? ( test )"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

RDEPEND="
	dev-db/sqlite
	python? ( ${PYTHON_DEPS} )
"
DEPEND="${RDEPEND}"
# The pytest suite exercises the built loadable extension directly
# (conftest loads dist/vec0); the python binding itself has no dedicated
# tests. The python test toolchain is only pulled with the python flag.
BDEPEND="
	test? (
		python? (
			dev-python/numpy
			dev-python/pytest
			dev-python/syrupy
		)
	)
"

# tests/afbd is a CLI benchmark script importing deepdiff (no test
# functions), tests/correctness needs a dbpedia-embedded .npy dataset —
# neither is self-contained.
EPYTEST_IGNORE=(
	tests/afbd
	tests/correctness
)

src_prepare() {
	default
	# Generate sqlite-vec.h from the template the way upstream's Makefile
	# does (envsubst over VERSION/DATE/SOURCE + version components); the C
	# build needs it regardless of the python binding.
	local rest=${PV#*.}
	sed \
		-e "s|\${VERSION}|${PV}|g" \
		-e "s|\${VERSION_MAJOR}|${PV%%.*}|g" \
		-e "s|\${VERSION_MINOR}|${rest%%.*}|g" \
		-e "s|\${VERSION_PATCH}|${rest#*.}|g" \
		-e "s|\${DATE}|$(date -u +'%FT%TZ%z')|g" \
		-e "s|\${SOURCE}|v${PV} (tarball)|g" \
		sqlite-vec.h.tmpl > sqlite-vec.h || die

	# sqlite-vec-internal.h uses fixed-width types but relies on its
	# includers for <stdint.h>; upstream's `make test-unit` fails the same
	# way even with its vendored amalgamation.
	sed -i '/#include <stddef.h>/a #include <stdint.h>' \
		tests/sqlite-vec-internal.h || die
}

src_compile() {
	mkdir -p dist || die
	# The loadable extension, mirroring upstream `make loadable`
	# (our CPPFLAGS/CFLAGS/LDFLAGS apply; upstream hardcodes -O3).
	"$(tc-getCC)" ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} \
		-fPIC -shared -Wall -Wextra \
		sqlite-vec.c -o dist/vec0.so -lm || die "failed to build vec0.so"
}

src_test() {
	# C unit test, mirroring upstream `make test-unit`. Upstream statically
	# links a vendored sqlite amalgamation; our tests only exercise
	# sqlite-vec internals plus sqlite3_free, so the system dev-db/sqlite
	# (already in DEPEND) does the job.
	"$(tc-getCC)" ${CPPFLAGS} ${CFLAGS} ${LDFLAGS} \
		-DSQLITE_CORE -DSQLITE_VEC_TEST -I./ \
		tests/test-unit.c sqlite-vec.c \
		-o "${T}"/test-unit -lsqlite3 -lm || die "failed to build test-unit"
	"${T}"/test-unit || die "C unit tests failed"

	# The python suite loads dist/vec0 directly (no binding needed); its
	# files are named test-*.py (hyphens), which does not match pytest's
	# default test_*.py glob, hence the pattern override.
	if use python; then
		python_setup
		epytest -o python_files='test-*.py' tests/
	fi
}

src_install() {
	# The loadable extension for system-wide sqlite3 usage:
	# .load /usr/$(get_libdir)/vec0
	exeinto /usr/$(get_libdir)
	doexe dist/vec0.so

	if use python; then
		# Assemble the sqlite_vec python module the way sqlite-dist does for
		# the PyPI wheels: a base loader + bindings/python/extra_init.py,
		# bundling a copy of the extension.
		local module_dir="${T}/sqlite_vec"
		mkdir -p "${module_dir}" || die
		cat > "${module_dir}/__init__.py" <<-EOF || die
			from os import path
			import sqlite3

			__version__ = "${PV}"
			__version_info__ = tuple(__version__.split("."))

			def loadable_path():
			  """ Returns the full path to the sqlite-vec loadable SQLite extension bundled with this package """

			  loadable_path = path.join(path.dirname(__file__), "vec0")
			  return path.normpath(loadable_path)

			def load(conn: sqlite3.Connection)  -> None:
			  """ Load the sqlite-vec SQLite extension into the given database connection. """

			  conn.load_extension(loadable_path())

		EOF
		cat bindings/python/extra_init.py >> "${module_dir}/__init__.py" || die
		cp dist/vec0.so "${module_dir}/" || die
		python_foreach_impl python_domodule "${module_dir}"
	fi

	einstalldocs
}
