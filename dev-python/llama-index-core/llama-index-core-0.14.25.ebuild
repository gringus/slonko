# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 slonko-test

DESCRIPTION="Interface between LLMs and your data"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-core/
"
SRC_URI="
	https://github.com/run-llama/llama_index/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
	test? (
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe
			-> tiktoken-gpt2-vocab.bpe
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json
			-> tiktoken-gpt2-encoder.json
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken
			-> tiktoken-cl100k_base.tiktoken
		https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf
			-> ${P}-dummy.pdf
		https://storage.googleapis.com/generativeai-downloads/data/scene.jpg
			-> ${P}-scene.jpg
		https://astrabert.github.io/hophop-science/images/whale_doing_science.png
			-> ${P}-whale_doing_science.png
		https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png
			-> ${P}-googlelogo_color_272x92dp.png
	)
"
S="${WORKDIR}/llama_index-${PV}/llama-index-core"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Upstream wants sqlalchemy[asyncio]>=1.4.49; asyncio support is built
# into >=2.x and the tree no longer carries a matching USE flag, so pull the
# greenlet it implies explicitly (tree sqlalchemy ships it as optfeature).
RDEPEND="
	>=dev-python/aiohttp-3.8.6[${PYTHON_USEDEP}]
	<dev-python/aiohttp-4[${PYTHON_USEDEP}]
	dev-python/aiosqlite[${PYTHON_USEDEP}]
	>=dev-python/banks-2.3.0[${PYTHON_USEDEP}]
	<dev-python/banks-3[${PYTHON_USEDEP}]
	dev-python/dataclasses-json[${PYTHON_USEDEP}]
	>=dev-python/deprecated-1.2.9.3[${PYTHON_USEDEP}]
	dev-python/greenlet[${PYTHON_USEDEP}]
	>=dev-python/dirtyjson-1.0.8[${PYTHON_USEDEP}]
	<dev-python/dirtyjson-2[${PYTHON_USEDEP}]
	>=dev-python/filetype-1.2.0[${PYTHON_USEDEP}]
	<dev-python/filetype-2[${PYTHON_USEDEP}]
	>=dev-python/fsspec-2023.5.0[${PYTHON_USEDEP}]
	dev-python/httpx[${PYTHON_USEDEP}]
	>=dev-python/llama-index-workflows-2.14.0[${PYTHON_USEDEP}]
	<dev-python/llama-index-workflows-3[${PYTHON_USEDEP}]
	>=dev-python/nest-asyncio-1.5.8[${PYTHON_USEDEP}]
	<dev-python/nest-asyncio-2[${PYTHON_USEDEP}]
	>=dev-python/networkx-3.0[${PYTHON_USEDEP}]
	>=dev-python/nltk-3.9.3[${PYTHON_USEDEP}]
	dev-python/numpy[${PYTHON_USEDEP}]
	>=dev-python/pillow-9.0.0[${PYTHON_USEDEP}]
	dev-python/platformdirs[${PYTHON_USEDEP}]
	>=dev-python/pydantic-2.8.0[${PYTHON_USEDEP}]
	>=dev-python/pyyaml-6.0.1[${PYTHON_USEDEP}]
	>=dev-python/requests-2.31.0[${PYTHON_USEDEP}]
	>=dev-python/setuptools-80.9.0[${PYTHON_USEDEP}]
	>=dev-python/sqlalchemy-2.0[${PYTHON_USEDEP}]
	>=dev-python/tenacity-8.2.0[${PYTHON_USEDEP}]
	<dev-python/tenacity-10[${PYTHON_USEDEP}]
	>=dev-python/tiktoken-0.7.0[${PYTHON_USEDEP}]
	>=dev-python/tinytag-2.2.0[${PYTHON_USEDEP}]
	>=dev-python/tqdm-4.66.1[${PYTHON_USEDEP}]
	<dev-python/tqdm-5[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.5.0[${PYTHON_USEDEP}]
	>=dev-python/typing-inspect-0.8.0[${PYTHON_USEDEP}]
	dev-python/wrapt[${PYTHON_USEDEP}]
"

BDEPEND="
	test? (
		dev-python/beautifulsoup4[${PYTHON_USEDEP}]
		dev-python/nltk-data
		dev-python/openai[${PYTHON_USEDEP}]
		dev-python/pandas[${PYTHON_USEDEP}]
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
		dev-python/pytest-mock[${PYTHON_USEDEP}]
		dev-python/websockets[${PYTHON_USEDEP}]
	)
"

EPYTEST_DESELECT=(
	# pydantic 2.14 changed WrapSerializer handling; upstream tested
	# against 2.13.5, which the tree does not carry. Chat store
	# serialization regressed, the rest of the suite is fine.
	tests/memory/test_chat_memory_buffer.py::test_string_save_load
	tests/memory/test_chat_memory_buffer.py::test_dict_save_load
	tests/memory/test_chat_summary_memory_buffer.py::test_string_save_load
	tests/memory/test_chat_summary_memory_buffer.py::test_dict_save_load
	tests/storage/chat_store/test_simple_chat_store.py::test_persist_non_ascii_unescaped
	# llama-index-workflows 2.26 changed agent state handling; upstream
	# locked 2.24.0 at this tag.
	tests/agent/workflow/test_multi_agent_workflow.py::test_agent_with_hitl
)

EPYTEST_XDIST=1
distutils_enable_tests pytest

# dev-python/httpx is flagged deprecated in ::gentoo profiles (upstream not
# accepting bug reports); upstream hard-requires it and no replacement exists.

src_prepare() {
	default

	# Several tests fetch static resources (dummy.pdf, scene.jpg, two
	# images) from the internet; rewrite the URLs to a local http.server
	# started in src_test so the suite runs offline.
	use test || return 0
	local port=47471
	local -A map=(
		[https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf]=dummy.pdf
		[https://storage.googleapis.com/generativeai-downloads/data/scene.jpg]=scene.jpg
		[https://astrabert.github.io/hophop-science/images/whale_doing_science.png]=whale_doing_science.png
		[https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png]=googlelogo_color_272x92dp.png
	)
	local -a urls=()
	local url file
	for url in "${!map[@]}"; do
		urls+=( -e "s|${url}|http://127.0.0.1:${port}/${map[${url}]}|g" )
	done
	grep -rlF -f <(printf '%s\n' "${!map[@]}") tests/ |
		xargs sed -i "${urls[@]}" || die
}

src_test() {
	# Serve the static test resources fetched by the suite (see
	# src_prepare); the tree has no network in the build environment.
	local srv_dir="${T}"/test-www
	mkdir -p "${srv_dir}" || die
	local f
	for f in dummy.pdf scene.jpg whale_doing_science.png googlelogo_color_272x92dp.png; do
		cp "${DISTDIR}/${P}-${f}" "${srv_dir}/${f}" || die
	done
	slonko_test_spawn_server 47471 "${T}"/test-http-server.log \
		python3 -m http.server 47471 --bind 127.0.0.1 --directory "${srv_dir}"

	# The suite calls tiktoken.get_encoding("cl100k_base")/"gpt2" and
	# encoding_for_model("gpt-3.5-turbo"), which fetch the files from
	# openaipublic on first use (the package's bundled _static cache is
	# empty). Pre-seed TIKTOKEN_CACHE_DIR (filenames are sha1 of the blob
	# URL) so everything runs offline.
	slonko_test_seed_tiktoken_cache "${T}"/tiktoken-cache <<-EOF
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe|tiktoken-gpt2-vocab.bpe
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json|tiktoken-gpt2-encoder.json
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken|tiktoken-cl100k_base.tiktoken
	EOF

	# The default SentenceSplitter/tokenizer path seeds punkt_tab and
	# stopwords via nltk.data.find(paths=[NLTK_DATA]) — which searches only
	# NLTK_DATA — and would download on miss. Point it at the data installed
	# by dev-python/nltk-data (corpora/stopwords + tokenizers/punkt_tab).
	local -x NLTK_DATA="${EPREFIX}/usr/share/nltk_data"

	distutils-r1_src_test

	slonko_test_stop_server
}
