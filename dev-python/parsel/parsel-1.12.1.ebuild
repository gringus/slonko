# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..15} )
DISTUTILS_USE_PEP517=hatchling
inherit distutils-r1

DESCRIPTION="Utility to extract data from XML/HTML documents using XPath or CSS selectors"
HOMEPAGE="
	https://scrapy.org/
	https://pypi.org/project/parsel/
	https://github.com/scrapy/parsel
"
SRC_URI="https://github.com/scrapy/${PN}/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="BSD"
SLOT=0
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/cssselect-1.2.0[${PYTHON_USEDEP}]
	>=dev-python/jmespath-1.0.0[${PYTHON_USEDEP}]
	>=dev-python/lxml-5.1.0[${PYTHON_USEDEP}]
	>=dev-python/w3lib-1.19.0[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/psutil[${PYTHON_USEDEP}]
		dev-python/sybil[${PYTHON_USEDEP}]
	)
"

EPYTEST_DESELECT=(
	# cssselect 1.6.0 (2026-10-09) added a contains(@class, ...) fast path
	# to class-selector XPath output; parsel 1.12.1 predates it and its
	# test expectations + one docs example assert the old form. The new
	# XPath is functionally equivalent. Fixed upstream by 893eb22ff
	# ("Fix tests with cssselect 1.6.0", #384); drop these once that lands
	# in a release.
	tests/test_selector_csstranslator.py::test_css2xpath
	docs/usage.rst::line:1280,column:1
	docs/usage.rst::line:1282,column:1
)

EPYTEST_PLUGINS=( )
distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/sphinx-notfound-page \
	dev-python/sphinx-rtd-theme
