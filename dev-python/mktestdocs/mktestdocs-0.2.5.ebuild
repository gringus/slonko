# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

DESCRIPTION="Run pytest against markdown files/docstrings"
HOMEPAGE="
	https://pypi.org/project/mktestdocs/
	https://github.com/koaning/mktestdocs
"
SRC_URI="https://github.com/koaning/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DOCS=( README.md )

distutils_enable_tests pytest
