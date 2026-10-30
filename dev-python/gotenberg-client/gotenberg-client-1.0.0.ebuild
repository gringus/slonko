# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{10..14} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="A Python client for interfacing with the Gotenberg API"
HOMEPAGE="
	https://github.com/stumpylog/gotenberg-client
	https://pypi.org/project/gotenberg-client/
"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/typing-extensions[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="
	test? (
		>=dev-python/httpx-0.27[${PYTHON_USEDEP}]
		dev-python/httpx2[${PYTHON_USEDEP}]
		dev-python/pikepdf[${PYTHON_USEDEP}]
		dev-python/pypdf[${PYTHON_USEDEP}]
		dev-python/requests[${PYTHON_USEDEP}]
	)
"

DOCS=( README.md )

EPYTEST_PLUGINS=( flaky pytest-{asyncio,httpx,mock} )
EPYTEST_IGNORE=(
	# requires niquests (tests the niquests backend selection)
	tests/test_backend_auto.py
)
distutils_enable_tests pytest

python_test() {
	# 'live' tests require a running Gotenberg server (Docker); the niquests
	# backend is unpackaged. Everything else runs against pytest-httpx mocks.
	epytest -m 'not live and not niquests' tests
}

pkg_postinst() {
	optfeature "httpx support" dev-python/httpx
	optfeature "magic support" dev-python/magic
	optfeature "niquests support" dev-python/niquests
	optfeature "requests support" dev-python/requests
}
