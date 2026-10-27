# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..15} pypy3 )
DISTUTILS_USE_PEP517=hatchling
inherit distutils-r1 pypi

DESCRIPTION="Library of web-related functions"
HOMEPAGE="
	https://scrapy.org/
	https://pypi.org/project/w3lib/
	https://github.com/scrapy/w3lib
"

LICENSE="BSD"
SLOT=0
KEYWORDS="~amd64"

BDEPEND="
	test? (
		dev-python/hypothesis[${PYTHON_USEDEP}]
	)
"

# pytest-codspeed benchmarks are importorskip-guarded
EPYTEST_PLUGINS=( hypothesis )
distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/sphinx-notfound-page \
	dev-python/sphinx-rtd-theme
