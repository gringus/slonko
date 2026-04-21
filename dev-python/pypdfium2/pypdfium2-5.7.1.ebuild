# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )

inherit distutils-r1

DESCRIPTION="pypdfium2 is an ABI-level Python 3 binding to PDFium"
HOMEPAGE="https://github.com/pypdfium2-team/pypdfium2"
SRC_URI="https://github.com/pypdfium2-team/${PN}/archive/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="Apache-2.0 BSD CC-BY-4.0 LGPL-3 MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	=app-text/pdfium-7802
"
BDEPEND="
	test? (
		dev-python/pillow[jpeg,jpeg2k,lcms,tiff,truetype,zlib,${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
	)
"
PATCHES=(
	"${FILESDIR}"/run_cmd.patch
)

DOCS=( README.md )

EPYTEST_PLUGINS=( )
distutils_enable_tests pytest
distutils_enable_sphinx docs/source \
	dev-python/myst-parser \
	dev-python/sphinx-issues \
	dev-python/sphinx-rtd-theme \
	dev-python/sphinxcontrib-programoutput

EPYTEST_DESELECT=(
	"tests/test_misc.py::test_const_converters[mapping11-True-items11]"
)

src_configure() {
	export PDFIUM_PLATFORM="system-search"
	distutils-r1_src_configure
}
