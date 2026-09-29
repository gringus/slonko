# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="A fixtures replacement based on thoughtbot's factory_girl"
HOMEPAGE="https://github.com/FactoryBoy/factory_boy"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=">=dev-python/faker-0.7.0[${PYTHON_USEDEP}]"

BDEPEND="
	test? (
		dev-python/django[${PYTHON_USEDEP}]
		dev-python/pillow[jpeg,${PYTHON_USEDEP}]
		dev-python/sqlalchemy[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests unittest
distutils_enable_sphinx docs \
	dev-python/sphinx-rtd-theme
