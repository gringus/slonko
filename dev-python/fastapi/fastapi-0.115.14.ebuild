# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=pdm-backend
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="High performance framework, easy to learn, fast to code, ready for production"
HOMEPAGE="https://fastapi.tiangolo.com/ https://pypi.org/project/fastapi/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm64 x86"

RESTRICT="test"

RDEPEND="
	>=dev-python/starlette-0.27.0[${PYTHON_USEDEP}]
	>=dev-python/pydantic-1.7.4[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.8.0[${PYTHON_USEDEP}]
	>=dev-python/anyio-3.7.1[${PYTHON_USEDEP}]
"
