# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..14} )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1 optfeature

DESCRIPTION="Date parsing library designed to parse dates from HTML pages"
HOMEPAGE="https://github.com/scrapinghub/dateparser"
SRC_URI="https://github.com/scrapinghub/${PN}/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="BSD-4"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/python-dateutil-2.7.0[${PYTHON_USEDEP}]
	>=dev-python/pytz-2024.2[${PYTHON_USEDEP}]
	>=dev-python/regex-2024.9.11[${PYTHON_USEDEP}]
	>=dev-python/tzlocal-0.2[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/gitpython[${PYTHON_USEDEP}]
		dev-python/convertdate[${PYTHON_USEDEP}]
		dev-python/hijridate[${PYTHON_USEDEP}]
		dev-python/langdetect[${PYTHON_USEDEP}]
		dev-python/parameterized[${PYTHON_USEDEP}]
		dev-python/parsel[${PYTHON_USEDEP}]
		dev-python/ruamel-yaml[${PYTHON_USEDEP}]
	)
"
EPYTEST_DESELECT=(
	dateparser/date.py::dateparser.date.DateDataParser.get_date_data
	dateparser/search/__init__.py::dateparser.search.search_dates
)

distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/sphinx-rtd-theme

python_prepare_all() {
	# Require atheris fuzzer
	rm -rf fuzzing

	distutils-r1_python_prepare_all
}

pkg_postinst() {
	optfeature "calendars support" "dev-python/hijridate dev-python/convertdate"
	optfeature "operations on language files" dev-python/ruamel-yaml
	optfeature "language detection support" dev-python/langdetect
}
