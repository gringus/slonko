# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="llama-index embeddings openai like integration"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-embeddings-openai-like/
"
# The sdist ships no tests; pin the llama_index monorepo commit that
# carries this version (the last touching this package's pyproject).
SRC_URI="
	https://github.com/run-llama/llama_index/archive/98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27.tar.gz
		-> llama_index-98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27.gh.tar.gz
"
S="${WORKDIR}/llama_index-98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27/llama-index-integrations/embeddings/llama-index-embeddings-openai-like"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/llama-index-core-0.13.0[${PYTHON_USEDEP}]
	<dev-python/llama-index-core-0.15[${PYTHON_USEDEP}]
	>=dev-python/llama-index-embeddings-openai-0.6.0[${PYTHON_USEDEP}]
	<dev-python/llama-index-embeddings-openai-0.7[${PYTHON_USEDEP}]
"

distutils_enable_tests pytest
