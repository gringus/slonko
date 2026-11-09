# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="llama-index llms ollama integration"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-llms-ollama/
"
# The sdist ships no tests; they live in the llama_index monorepo, whose
# v0.14.25 tag carries exactly this version. Reuse the distfile
# dev-python/llama-index-core digests (same tarball).
SRC_URI="
	https://github.com/run-llama/llama_index/archive/refs/tags/v0.14.25.tar.gz
		-> llama-index-core-0.14.25.gh.tar.gz
"
S="${WORKDIR}/llama_index-0.14.25/llama-index-integrations/llms/llama-index-llms-ollama"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/llama-index-core-0.14.5[${PYTHON_USEDEP}]
	<dev-python/llama-index-core-0.15[${PYTHON_USEDEP}]
	>=dev-python/ollama-0.5.3[${PYTHON_USEDEP}]
"

BDEPEND="
	test? (
		dev-python/pytest-asyncio[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest

_ollama_llms_kill_server() {
	[[ -n ${_OLLAMA_MOCK_PID} ]] && kill "${_OLLAMA_MOCK_PID}" 2>/dev/null
}
EBUILD_DEATH_HOOKS+=" _ollama_llms_kill_server"

src_test() {
	# The upstream suite is a live-server integration test; run it against
	# a local mock of the ollama API (the wrapper's client hardcodes its
	# default host, localhost:11434).
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
		_ollama_llms_kill_server
		die "mock ollama server failed to start"
	fi

	distutils-r1_src_test

	_ollama_llms_kill_server
}
