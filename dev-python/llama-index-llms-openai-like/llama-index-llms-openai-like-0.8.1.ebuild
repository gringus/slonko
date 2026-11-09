# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="llama-index llms openai-like integration"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-llms-openai-like/
"
# The sdist ships no tests; pin the llama_index monorepo commit that
# carries this version (the last touching this package's pyproject).
SRC_URI="
	https://github.com/run-llama/llama_index/archive/139761450a1e43c65042b10d01be6bb3605534ed.tar.gz
		-> ${P}.gh.tar.gz
	test? (
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken
			-> tiktoken-cl100k_base.tiktoken
	)
"
S="${WORKDIR}/llama_index-139761450a1e43c65042b10d01be6bb3605534ed/llama-index-integrations/llms/llama-index-llms-openai-like"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/llama-index-core-0.14.3[${PYTHON_USEDEP}]
	<dev-python/llama-index-core-0.15[${PYTHON_USEDEP}]
	>=dev-python/llama-index-llms-openai-0.8.0[${PYTHON_USEDEP}]
	<dev-python/llama-index-llms-openai-0.9[${PYTHON_USEDEP}]
"

# Live-API tests self-skip without OPENAI_API_KEY; the rest mock via
# unittest.
BDEPEND="
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest

src_test() {
	# The tests mock the OpenAI HTTP layer but still tokenize via
	# llama-index-core's default tokenizer, which fetches the cl100k_base
	# encoding from openaipublic on first use; pre-seed TIKTOKEN_CACHE_DIR
	# (filename is sha1 of the blob URL).
	local cache_dir="${T}"/tiktoken-cache
	mkdir -p "${cache_dir}" || die
	local url='https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken'
	cp "${DISTDIR}/tiktoken-cl100k_base.tiktoken" \
		"${cache_dir}/$(printf '%s' "${url}" | sha1sum | awk '{print $1}')" || die
	local -x TIKTOKEN_CACHE_DIR="${cache_dir}"

	distutils-r1_src_test
}
