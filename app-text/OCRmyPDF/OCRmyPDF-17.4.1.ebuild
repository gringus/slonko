# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 optfeature shell-completion

DESCRIPTION="OCRmyPDF adds an OCR text layer to scanned PDF files"
HOMEPAGE="https://github.com/ocrmypdf/OCRmyPDF"

if [[ "${PV}" =~ 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/ocrmypdf/OCRmyPDF"
else
	SRC_URI="https://github.com/ocrmypdf/OCRmyPDF/archive/v${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="bash-completion fish-completion"

RDEPEND="
	>=app-text/ghostscript-gpl-9.54
	>=app-text/pdfminer-20220319[${PYTHON_USEDEP}]
	>=app-text/tesseract-4.1.1[jpeg,tiff,png,webp]
	>=dev-python/deprecation-2.1.0[${PYTHON_USEDEP}]
	>=dev-python/fpdf2-2.8.0[${PYTHON_USEDEP}]
	>=dev-python/packaging-20[${PYTHON_USEDEP}]
	>=dev-python/pikepdf-10[${PYTHON_USEDEP}]
	>=dev-python/pillow-10.0.1[jpeg,jpeg2k,lcms,tiff,webp,zlib,${PYTHON_USEDEP}]
	>=dev-python/pluggy-1[${PYTHON_USEDEP}]
	>=dev-python/pypdfium2-5.0.0[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.12.5[${PYTHON_USEDEP}]
	>=dev-python/rich-13[${PYTHON_USEDEP}]
	>=dev-python/uharfbuzz-0.53.2[${PYTHON_USEDEP}]
	>=media-gfx/img2pdf-0.5[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		app-text/poppler
		>=app-text/unpaper-6.1
		>=dev-python/hypothesis-6.36.0[${PYTHON_USEDEP}]
		>=dev-python/pytest-xdist-2.5.0[${PYTHON_USEDEP}]
		dev-python/python-dotenv[${PYTHON_USEDEP}]
		dev-python/python-xmp-toolkit[${PYTHON_USEDEP}]
		>=dev-python/reportlab-3.6.8[${PYTHON_USEDEP}]
		media-fonts/noto
		media-fonts/noto-cjk
		>=media-libs/jbig2enc-0.29
		>=media-gfx/pngquant-2.5
		app-text/tessdata_fast[l10n_de]
	)
"

EPYTEST_PLUGINS=()
EPYTEST_XDIST=1
# Too many dependencies
EPYTEST_IGNORE=(
	tests/test_watcher.py
)
EPYTEST_DESELECT=(
	# Recompressing/Deflating JPEGs
	tests/test_hocrtransform.py::test_fpdf2_matches_sandwich
	# Known language issues
	tests/test_multilingual_direct.py::TestMultilingual::test_render_multilingual_hocr_basic
	tests/test_fpdf_renderer.py::TestWordSegmentation::test_cjk_no_spurious_spaces
)
distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/myst-parser \
	dev-python/sphinx-issues \
	dev-python/sphinx-rtd-theme \
	dev-python/sphinxcontrib-mermaid

python_test() {
	epytest --runslow
}

src_prepare() {
	distutils-r1_src_prepare

	# Remove non-existing modules for doc generation
	sed \
	-e '/sphinx_reredirects/d' \
		-i docs/conf.py || die
}

src_install() {
	distutils-r1_src_install

	use bash-completion &&
		newbashcomp misc/completion/ocrmypdf.bash "${PN,,}"
	use fish-completion &&
		newfishcomp misc/completion/ocrmypdf.fish "${PN,,}"
}

pkg_postinst() {
	optfeature "JBIG2 optimization support" media-libs/jbig2enc
	optfeature "image cleaning support" app-text/unpaper
	optfeature "PNG optimization support" media-gfx/pngquant
}
