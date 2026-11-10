# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="llama-index embeddings openai integration"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-embeddings-openai/
"
# The sdist ships no tests; pin the llama_index monorepo commit just
# before the 0.7.0 version bump (this package must stay <0.7 for
# llama-index-embeddings-openai-like).
SRC_URI="
	https://github.com/run-llama/llama_index/archive/39f481fc41d1da26cf511ef697762b3b0a93636d.tar.gz
		-> llama_index-39f481fc41d1da26cf511ef697762b3b0a93636d.gh.tar.gz
"
S="${WORKDIR}/llama_index-39f481fc41d1da26cf511ef697762b3b0a93636d/llama-index-integrations/embeddings/llama-index-embeddings-openai"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Must stay <0.7: llama-index-embeddings-openai-like pins <0.7,>=0.6.0.
RDEPEND="
	>=dev-python/llama-index-core-0.13.0[${PYTHON_USEDEP}]
	<dev-python/llama-index-core-0.15[${PYTHON_USEDEP}]
	>=dev-python/openai-1.1.0[${PYTHON_USEDEP}]
"

distutils_enable_tests pytest
