# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=flit-core
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Read audio file metadata"
HOMEPAGE="
	https://github.com/tinytag/tinytag
	https://pypi.org/project/tinytag/
"
# The PyPI sdist ships no tests; the GitHub tarball carries the unittest
# suite together with CC0-licensed sample files.
SRC_URI="https://github.com/tinytag/tinytag/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"
S="${WORKDIR}/tinytag-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

distutils_enable_tests unittest
