# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )

inherit distutils-r1

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
		app-arch/brotli[python]
		app-text/qpdf
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
	# Stale fixture in the 2.8.9 tarball: Pillow 13 (2026-10-16) changed
	# LANCZOS resampling output, and upstream regenerated this fixture on
	# master (2ee9b3ce1, 2026-10-20) but too late for 2.8.9. The test
	# resizes an image to 500x500, so the embedded pixels differ; the rest
	# of the fixture is byte-identical and the 2.8.9 engine is unaffected
	# (verified qpdf-normalized against the upstream master fixture).
	# Drop this deselect once 2.8.10+ ships the regenerated fixture.
	test/image/test_full_page_image.py::test_image_with_explicit_dimensions
)

python_test() {
	epytest -o addopts=
}
