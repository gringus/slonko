# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=uv-build
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 slonko-test

DESCRIPTION="Event-driven, async-first, step-based control flow for LLM apps"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-workflows/
"
# The sdist ships no tests; the package is developed in the llama-agents
# repo (packages/llama-index-workflows) since it moved out of the llama_index
# monorepo. Pin the version-bump commit that released ${PV}.
SRC_URI="
	https://github.com/run-llama/llama-agents/archive/6a612d9414971f579b4af7281332ef6d339080bc.tar.gz
		-> ${P}.gh.tar.gz
	test? (
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken
			-> tiktoken-cl100k_base.tiktoken
	)
"
S="${WORKDIR}/llama-agents-6a612d9414971f579b4af7281332ef6d339080bc/packages/llama-index-workflows"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/llama-index-instrumentation-0.4.3[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.11.5[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.6.0[${PYTHON_USEDEP}]
"

# The retry-signature conformance tests expect the tenacity 9.1.x API
# (upstream locked 9.1.2); 9.2 changed the signatures.
BDEPEND="
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
		dev-python/pytest-timeout[${PYTHON_USEDEP}]
		>=dev-python/tenacity-9.1.2 <dev-python/tenacity-9.2
		dev-python/time-machine[${PYTHON_USEDEP}]
		dev-python/tiktoken[${PYTHON_USEDEP}]
	)
"

EPYTEST_XDIST=1
distutils_enable_tests pytest

src_test() {
	# tests/context/test_state_copy.py fetches the cl100k_base encoding on
	# first use; pre-seed TIKTOKEN_CACHE_DIR (filename is sha1 of the blob
	# URL) so it runs offline.
	slonko_test_seed_tiktoken_cache "${T}"/tiktoken-cache <<-EOF
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken|tiktoken-cl100k_base.tiktoken
	EOF

	distutils-r1_src_test
}
