# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Runtime inspection utilities for Python typing module"
HOMEPAGE="
	https://github.com/ilevkivskyi/typing_inspect
	https://pypi.org/project/typing-inspect/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/mypy-extensions-0.3.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-3.7.4[${PYTHON_USEDEP}]
"

# get_parameters() on a subscripted Union returns () on Python 3.11+;
# the test asserts pre-3.11 typing internals and upstream is unmaintained
# (last release 2023).
EPYTEST_DESELECT=(
	test_typing_inspect.py::GetUtilityTestCase::test_parameters
)
distutils_enable_tests pytest
