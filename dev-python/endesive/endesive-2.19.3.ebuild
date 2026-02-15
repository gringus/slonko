# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..13} )

inherit distutils-r1

DESCRIPTION="Sign and verify digital signatures in mail, PDF and XML documents"
HOMEPAGE="
	https://pypi.org/project/endesive/
	https://github.com/m32/endesive
"

SRC_URI="https://github.com/m32/endesive/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"
LICENSE="MIT LGPL-3 BSD"
SLOT="0"
KEYWORDS="amd64"
IUSE="examples"

RDEPEND="
	dev-python/asn1crypto[${PYTHON_USEDEP}]
	dev-python/attrs[${PYTHON_USEDEP}]
	dev-python/certifi[${PYTHON_USEDEP}]
	dev-python/cryptography[${PYTHON_USEDEP}]
	dev-python/lxml[${PYTHON_USEDEP}]
	dev-python/paramiko[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/pykcs11[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
"
BDEPEND="
	test?  (
		dev-libs/softhsm
		media-fonts/dejavu
	)
"

DOCS=( README.rst )

PATCHES=(
	"${FILESDIR}/${PN}-2.16-test-import.patch"
	"${FILESDIR}/${PN}-2.16-fontdir.patch"
)

distutils_enable_tests unittest
distutils_enable_sphinx docs \
	dev-python/sphinx-rtd-theme

src_prepare() {
	default

	# Missing ssh agent
	sed -i -re \
		's/def (test_ssh_sign|test_ssh_verify)/def _\1/' \
		tests/test_hsm.py || die
	# Requires network
	sed -i -re \
		's/def (test_pdf_timestamp)/def _\1/' \
		tests/test_pdf.py || die
}

python_install_all() {
	if use examples; then
		dodoc -r examples
	fi

	distutils-r1_python_install_all
}
