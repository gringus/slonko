# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Image hashing library computing perceptual hashes"
HOMEPAGE="https://github.com/JohannesBuchner/imagehash"
# PyPI sdist omits tests/__init__.py and tests/utils.py; use the git archive
SRC_URI="https://github.com/JohannesBuchner/${PN}/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/numpy[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/pywavelets[${PYTHON_USEDEP}]
	dev-python/scipy[${PYTHON_USEDEP}]
"

DOCS=( README.rst )

BDEPEND="
	test? (
		dev-python/packaging[${PYTHON_USEDEP}]
		dev-python/six[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest
