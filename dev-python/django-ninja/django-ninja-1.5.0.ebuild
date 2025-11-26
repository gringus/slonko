# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DOCS_BUILDER="mkdocs"
DOCS_DEPEND="
	dev-python/markdown-include
	dev-python/mkdocs-material
	dev-python/mkdocstrings-python
"
DOCS_DIR="docs"

DISTUTILS_USE_PEP517=flit
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 docs pypi

DESCRIPTION="Fast Django REST Framework"
HOMEPAGE="
	https://django-ninja.dev/
	https://github.com/vitalik/django-ninja
"

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

EPYTEST_PLUGINS=( pytest-{asyncio,django} )
distutils_enable_tests pytest
