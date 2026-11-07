# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=flit-core
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="A lightweight library for converting complex datatypes to and from native Python datatypes"
HOMEPAGE="
	https://github.com/marshmallow-code/marshmallow
	https://pypi.org/project/marshmallow/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="dev-python/packaging[${PYTHON_USEDEP}]"

BDEPEND="
	test? (
		dev-python/simplejson[${PYTHON_USEDEP}]
	)
"

# CPython 3.14 reworded the datetime overflow error
# ("year must be in 1..9999" instead of "... is out of range").
EPYTEST_DESELECT=(
	tests/test_utils.py::test_from_timestamp_with_overflow_value
)
distutils_enable_tests pytest
