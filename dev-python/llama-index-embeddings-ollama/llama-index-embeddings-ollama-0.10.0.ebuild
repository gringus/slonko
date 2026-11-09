# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="llama-index embeddings ollama integration"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-embeddings-ollama/
"
# The sdist ships no tests; pin the llama_index monorepo commit that
# carries this version (the last touching this package's pyproject).
SRC_URI="
	https://github.com/run-llama/llama_index/archive/98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27.tar.gz
		-> llama_index-98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27.gh.tar.gz
"
S="${WORKDIR}/llama_index-98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27/llama-index-integrations/embeddings/llama-index-embeddings-ollama"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Upstream metadata wrongly hard-requires pytest-asyncio (packaging bug).
RDEPEND="
	>=dev-python/llama-index-core-0.13.0[${PYTHON_USEDEP}]
	<dev-python/llama-index-core-0.15[${PYTHON_USEDEP}]
	>=dev-python/ollama-0.3.1[${PYTHON_USEDEP}]
"

BDEPEND="
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest

_ollama_emb_kill_server() {
	[[ -n ${_OLLAMA_MOCK_PID} ]] && kill "${_OLLAMA_MOCK_PID}" 2>/dev/null
}
EBUILD_DEATH_HOOKS+=" _ollama_emb_kill_server"

src_test() {
	# The suite is a live-server integration test; run it against a local
	# mock of the ollama API (the wrapper's client hardcodes its default
	# host, localhost:11434).
	local mock="${T}"/mock-ollama-server.py
	cp "${FILESDIR}/mock-ollama-server.py" "${mock}" || die
	python3 "${mock}" &>"${T}"/mock-ollama-server.log &
	_OLLAMA_MOCK_PID=${!}
	local i
	for (( i = 0; i < 50; i++ )); do
		(echo > /dev/tcp/127.0.0.1/11434) 2>/dev/null && break
		sleep 0.1
	done
	if ! (echo > /dev/tcp/127.0.0.1/11434) 2>/dev/null; then
		_ollama_emb_kill_server
		die "mock ollama server failed to start"
	fi

	distutils-r1_src_test

	_ollama_emb_kill_server
}
