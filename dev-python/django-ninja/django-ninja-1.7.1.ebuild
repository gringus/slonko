# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=flit
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Fast Django REST Framework"
HOMEPAGE="
	https://django-ninja.dev/
	https://github.com/vitalik/django-ninja
"
# Upstream ships tests only in the git tree; the PyPI sdist carries neither
# tests nor docs as of 1.7.1.
SRC_URI="https://github.com/vitalik/${PN}/archive/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/django[${PYTHON_USEDEP}]
	dev-python/pydantic[${PYTHON_USEDEP}]
"
BDEPEND="
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
		dev-python/pytest-django[${PYTHON_USEDEP}]
		dev-python/psycopg[${PYTHON_USEDEP}]
	)
"

# tests: decimal JSON schema has no pattern since pydantic 2.14
# https://github.com/vitalik/django-ninja/commit/722b28bce, #1797
PATCHES=(
	"${FILESDIR}/${P}-pydantic-2.14-test.patch"
)

EPYTEST_PLUGINS=( pytest-{asyncio,django} )
distutils_enable_tests pytest
