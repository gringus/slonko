# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Adapted from ::stuff (istitov), test support from ::guru

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

# The Stainless spec bucket referenced by .stats.yml no longer exists; the
# identical spec generation ships in the v3.0.0 tag (openapi_spec_hash and
# openapi_transformed_spec_hash in .castiron.stats.yml match this release)
# and is what upstream scripts/mock feeds to the mock server.
STAINLESS_SPEC_BASE_URI=https://raw.githubusercontent.com/openai/openai-python
STAINLESS_SPEC_PATH=v3.0.0/api_reference/openapi.transformed.yml
# See https://github.com/openai/openai-python/blob/v${PV}/scripts/mock
STAINLESS_MOCK_SERVER_VERSION=0.22.1
STAINLESS_MOCK_SERVER_PACKAGE_JSON="${FILESDIR}/${P}-mock-server-package.json"

inherit distutils-r1 stainless-python

MY_PN="openai-python"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="The official Python library for the openai API"
HOMEPAGE="
	https://github.com/openai/openai-python
	https://pypi.org/project/openai/
"
SRC_URI+="
	https://github.com/openai/${MY_PN}/archive/refs/tags/v${PV}.tar.gz
		-> ${MY_P}.gh.tar.gz
"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/anyio-3.5.0[${PYTHON_USEDEP}]
	>=dev-python/distro-1.7.0[${PYTHON_USEDEP}]
	>=dev-python/httpx-0.23.0[${PYTHON_USEDEP}]
	>=dev-python/jiter-0.10.0[${PYTHON_USEDEP}]
	>=dev-python/pydantic-1.9.0[${PYTHON_USEDEP}]
	dev-python/sniffio[${PYTHON_USEDEP}]
	>=dev-python/tqdm-4.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.14[${PYTHON_USEDEP}]
"

BDEPEND="
	dev-python/hatch-fancy-pypi-readme[${PYTHON_USEDEP}]
	test? (
		>=dev-python/botocore-1.42.97[${PYTHON_USEDEP}]
		dev-python/dirty-equals[${PYTHON_USEDEP}]
		>=dev-python/httpx2-2.7.0[${PYTHON_USEDEP}] <dev-python/httpx2-3[${PYTHON_USEDEP}]
		dev-python/httpx-aiohttp[${PYTHON_USEDEP}]
		>=dev-python/jsonschema-4.23.0[${PYTHON_USEDEP}]
	)
"

EPYTEST_PLUGINS=(
	inline-snapshot
	nest-asyncio
	pytest-{asyncio,xdist}
	respx
	time-machine
)
distutils_enable_tests pytest
