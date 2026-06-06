# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )
PYTHON_REQ_USE="sqlite,tk?,xml(+)"

inherit distutils-r1

DESCRIPTION="Natural Language Toolkit"
HOMEPAGE="https://www.nltk.org/ https://github.com/nltk/nltk/"
SRC_URI="https://github.com/nltk/nltk/archive/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~ppc64 ~riscv x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos"
IUSE="tk"
REQUIRED_USE="test? ( tk )"

RDEPEND="
	dev-python/click[${PYTHON_USEDEP}]
	dev-python/joblib[${PYTHON_USEDEP}]
	dev-python/regex[${PYTHON_USEDEP}]
	dev-python/tqdm[${PYTHON_USEDEP}]"
BDEPEND="
	test? (
		>=dev-python/nltk-data-20260606
		dev-python/matplotlib[${PYTHON_USEDEP}]
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/pyparsing[${PYTHON_USEDEP}]
		dev-python/scikit-learn[${PYTHON_USEDEP}]
		dev-python/scipy[${PYTHON_USEDEP}]
		dev-python/twython[${PYTHON_USEDEP}]
	)
"
PDEPEND=">=dev-python/nltk-data-20260606"
PATCHES=(
    "${FILESDIR}/scikit-learn-1.9.patch"
)

EPYTEST_PLUGINS=( pytest-mock )
EPYTEST_IGNORE=(
	# Network required
	nltk/test/unit/test_downloader.py
)
distutils_enable_tests pytest
