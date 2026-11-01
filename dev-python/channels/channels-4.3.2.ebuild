# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )

inherit distutils-r1

DESCRIPTION="Extends Django abilities beyond HTTP protocol"
HOMEPAGE="https://github.com/django/channels"
SRC_URI="https://github.com/django/${PN}/archive/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	>=dev-python/asgiref-3.5.0[${PYTHON_USEDEP}]
	>=dev-python/django-4.2[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/async-timeout[${PYTHON_USEDEP}]
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
		dev-python/pytest-django[${PYTHON_USEDEP}]
	)
"

PATCHES=(
	# stub out channels.testing.live so that channels.testing (imported by
	# most test modules) does not pull in daphne; no test actually uses it
	"${FILESDIR}/${P}-mock-live-tests.patch"
)

EPYTEST_IGNORE=(
	# selenium browser tests, need a webdriver we do not install
	tests/sample_project/tests/test_selenium.py
)

EPYTEST_PLUGINS=( pytest-django pytest-asyncio )
distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/sphinx-rtd-theme

src_prepare() {
	default

	# drop daphne from the sample project INSTALLED_APPS; the file is only
	# used by the tests and Django setup would fail without daphne installed
	sed -i '/\s*"daphne",\s*$/d' tests/sample_project/config/settings.py || die
}

python_install() {
	distutils-r1_python_install
	rm -rf "${D}$(python_get_sitedir)"/tests || die
}
