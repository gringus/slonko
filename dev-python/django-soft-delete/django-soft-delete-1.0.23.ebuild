# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )
COMMIT="61b5340ec96ad0c061f38272a7a8c23b6e15b3d3"

inherit distutils-r1

DESCRIPTION="Soft delete models, managers, queryset for Django"
HOMEPAGE="https://github.com/san4ezy/django_softdelete"
SRC_URI="https://github.com/san4ezy/django_softdelete/archive/${COMMIT}.tar.gz -> ${P}.gh.tar.gz"
S="${WORKDIR}/django_softdelete-${COMMIT}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DOCS=( CHANGELOG.md README.md )

RDEPEND="dev-python/django[${PYTHON_USEDEP}]"
BDEPEND="
	test? (
		>=dev-python/pytest-django-4.8.0[${PYTHON_USEDEP}]
	)
"
EPYTEST_PLUGINS=( pytest-django )
distutils_enable_tests pytest

python_test() {
	local -x DJANGO_SETTINGS_MODULE=test_project.settings
	epytest --nomigrations
}
