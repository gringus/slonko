# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )

#DOCS_BUILDER="mkdocs"
#DOCS_DEPEND="
#	dev-python/lxml
#	dev-python/mkdocs-git-revision-date-localized-plugin
#	dev-python/mkdocs-material
#	dev-python/mkdocs-minify-plugin
#	dev-python/mkdocs-redirects
#	dev-python/pdoc3
#"

inherit distutils-r1 # docs

DESCRIPTION="Simple & fast PDF generation for Python"
HOMEPAGE="https://py-pdf.github.io/fpdf2/"
SRC_URI="https://github.com/py-pdf/${PN}/archive/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/defusedxml[${PYTHON_USEDEP}]
	dev-python/fonttools[${PYTHON_USEDEP}]
	dev-python/pillow[lcms,jpeg,jpeg2k,tiff,truetype,zlib,${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/cryptography[${PYTHON_USEDEP}]
		dev-python/endesive[${PYTHON_USEDEP}]
		dev-python/uharfbuzz[${PYTHON_USEDEP}]
		dev-python/pypdf[${PYTHON_USEDEP}]
		dev-python/qrcode[${PYTHON_USEDEP}]
	)
"

DOCS=( README.md )

EPYTEST_PLUGINS=( )
distutils_enable_tests pytest

EPYTEST_IGNORE=(
	# Requires dev-python/camelot-py
	test/table/test_table_extraction.py
)
EPYTEST_DESELECT=(
	# Requires network
	test/image/test_url_images.py::test_png_url
	test/layout/test_page_background.py::test_page_background
)

python_test() {
	epytest -o addopts=
}
