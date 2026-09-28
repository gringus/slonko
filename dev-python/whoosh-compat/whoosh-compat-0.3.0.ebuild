# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )
inherit distutils-r1 optfeature pypi

DESCRIPTION="Whoosh query-language parser emitting programmatic tantivy queries"
HOMEPAGE="
	https://pypi.org/project/whoosh-compat/
	https://github.com/stumpylog/whoosh-compat
"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

DEPEND=">=dev-python/python-dateutil-2.8[${PYTHON_USEDEP}]"
BDEPEND="
	test? (
		dev-python/hypothesis[${PYTHON_USEDEP}]
		dev-python/tantivy[${PYTHON_USEDEP}]
		dev-python/whoosh[${PYTHON_USEDEP}]
	)
	"

distutils_enable_tests pytest

pkg_postinst() {
	optfeature "tantivy support" dev-python/tantivy
}
