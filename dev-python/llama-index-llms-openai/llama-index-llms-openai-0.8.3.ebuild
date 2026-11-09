# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="llama-index llms openai integration"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-llms-openai/
"
# The sdist ships no tests; pin the llama_index monorepo commit that
# carries this version (the last touching this package's pyproject).
SRC_URI="
	https://github.com/run-llama/llama_index/archive/5b7b6e323e1da3edd787a2104a89257c14f026d0.tar.gz
		-> ${P}.gh.tar.gz
	test? (
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe
			-> tiktoken-gpt2-vocab.bpe
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json
			-> tiktoken-gpt2-encoder.json
		https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken
			-> tiktoken-r50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken
			-> tiktoken-p50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken
			-> tiktoken-cl100k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken
			-> tiktoken-o200k_base.tiktoken
	)
"
S="${WORKDIR}/llama_index-5b7b6e323e1da3edd787a2104a89257c14f026d0/llama-index-integrations/llms/llama-index-llms-openai"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/llama-index-core-0.14.5[${PYTHON_USEDEP}]
	<dev-python/llama-index-core-0.15[${PYTHON_USEDEP}]
	>=dev-python/openai-1.108.1[${PYTHON_USEDEP}]
	<dev-python/openai-3[${PYTHON_USEDEP}]
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
	# The tests tokenize via tiktoken's model registry, which fetches the
	# encodings from openaipublic on first use (different test models map
	# to different encodings); pre-seed TIKTOKEN_CACHE_DIR with all of them
	# (filenames are sha1 of the blob URLs).
	local cache_dir="${T}"/tiktoken-cache
	mkdir -p "${cache_dir}" || die
	local entry url distfile
	while read -r entry; do
		[[ -z ${entry} ]] && continue
		url=${entry%%|*}
		distfile=${entry#*|}
		cp "${DISTDIR}/${distfile}" "${cache_dir}/$(printf '%s' "${url}" | sha1sum | awk '{print $1}')" || die
	done <<-EOF
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe|tiktoken-gpt2-vocab.bpe
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json|tiktoken-gpt2-encoder.json
		https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken|tiktoken-r50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken|tiktoken-p50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken|tiktoken-cl100k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken|tiktoken-o200k_base.tiktoken
	EOF
	local -x TIKTOKEN_CACHE_DIR="${cache_dir}"

	distutils-r1_src_test
}
