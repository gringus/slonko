# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Instrumentation and Observability for LlamaIndex"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-instrumentation/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/deprecated-1.2.18[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.11.5[${PYTHON_USEDEP}]
"

BDEPEND="
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest
