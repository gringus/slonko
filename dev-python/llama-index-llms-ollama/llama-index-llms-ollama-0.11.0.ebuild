# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 slonko-test

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

src_test() {
	# The upstream suite is a live-server integration test; run it against
	# a local mock of the ollama API (the wrapper's client hardcodes its
	# default host, localhost:11434).
	slonko_test_write_ollama_mock "${T}"/mock-ollama-server.py
	slonko_test_spawn_server 11434 "${T}"/mock-ollama-server.log \
		python3 "${T}"/mock-ollama-server.py

	distutils-r1_src_test

	slonko_test_stop_server
}
