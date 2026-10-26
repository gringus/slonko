# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=meson-python
PYTHON_COMPAT=( python3_{12..15} )

inherit distutils-r1 git-r3 pypi

DESCRIPTION="A fast, fully typed HTML toolkit for Python, powered by a C-accelerated core"
HOMEPAGE="
	https://github.com/tox-dev/turbohtml/
	https://pypi.org/project/turbohtml/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	>=dev-build/meson-1.12.1
	test? (
		dev-python/coverage[${PYTHON_USEDEP}]
		dev-python/docutils[${PYTHON_USEDEP}]
		dev-python/elementpath[${PYTHON_USEDEP}]
		dev-python/feedparser[${PYTHON_USEDEP}]
		dev-python/html5lib[${PYTHON_USEDEP}]
		dev-python/httpx2[${PYTHON_USEDEP}]
		dev-python/jinja2[${PYTHON_USEDEP}]
		dev-python/linkify-it-py[${PYTHON_USEDEP}]
		dev-python/lxml[${PYTHON_USEDEP}]
		dev-python/markdown-it-py[${PYTHON_USEDEP}]
		dev-python/pandas[${PYTHON_USEDEP}]
		dev-python/pyquery[${PYTHON_USEDEP}]
		>=dev-python/pytest-9.1.1[${PYTHON_USEDEP}]
		dev-python/pytest-mock[${PYTHON_USEDEP}]
		dev-python/tenacity[${PYTHON_USEDEP}]
		dev-python/tinycss2[${PYTHON_USEDEP}]
		dev-python/typing-extensions[${PYTHON_USEDEP}]
	)
"

EPYTEST_PLUGINS=( pytest-mock )
distutils_enable_tests pytest

EPYTEST_IGNORE=(
	# require pyperf + pytest-codspeed
	tests/benchmarks
	# require unicodetools
	tests/conformance
	tests/url/test_idna.py
	# needs the fuzz-only extension build
	tests/test_fuzz_self_test.py
	# needs pyperf
	tests/test_bench_worker.py
)
EPYTEST_DESELECT=(
	# these patch re.sub globally to assert the C engine never falls back to
	# Python's re; epytest's junitxml plugin then calls re.sub on every test
	# report and the AssertionError kills the session with an INTERNALERROR
	tests/query/xpath/test_functions.py::test_regex_backreference_backtracking_limit_raises
	tests/query/xpath/test_functions.py::test_regex_matches_like_python_re
	tests/query/xpath/test_functions.py::test_regex_ignore_case_matches_like_python_re
	tests/query/xpath/test_functions.py::test_regex_word_boundary_on_empty_text
	tests/query/xpath/test_functions.py::test_regex_syntax_beyond_the_linear_engine_raises_value_error
	tests/query/xpath/test_functions.py::test_regex_malformed_pattern_raises_re_error
	tests/query/xpath/test_functions.py::test_regex_oversized_pattern_raises_value_error
	tests/query/xpath/test_functions.py::test_regex_replace_with_too_many_groups_raises_value_error
	tests/query/xpath/test_functions.py::test_re_replace_template_matches_python_re
	tests/query/xpath/test_functions.py::test_re_replace_malformed_template_raises
	tests/query/xpath/test_functions.py::test_fn_replace_dollar_references
	tests/query/xpath/test_functions.py::test_regex_flags_ignore_unknown_letters
)

src_unpack() {
	default

	if use test; then
		# html5lib-test
		local EGIT_REPO_URI="https://github.com/html5lib/html5lib-tests"
		local EGIT_CHECKOUT_DIR="${S}/tests/html5lib-tests"
		local EGIT_COMMIT="9fb614afaa42ce8787840f057b32084308e76549"

		git-r3_src_unpack
	fi
}
