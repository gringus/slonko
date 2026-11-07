# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="The official Python client library for ollama"
HOMEPAGE="
	https://github.com/ollama/ollama-python
	https://pypi.org/project/ollama/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/httpx-0.27[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.9[${PYTHON_USEDEP}]
"

EPYTEST_PLUGINS=( anyio pytest-httpserver )
distutils_enable_tests pytest

src_prepare() {
	# Upstream's addopts include --doctest-modules, which sweeps in
	# examples/*.py dialing a live Ollama server. The tests/ dir itself is
	# self-contained via pytest-httpserver (no daemon needed).
	sed -i -e "/--doctest-modules/d" pyproject.toml || die
	default
}
