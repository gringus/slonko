# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_1{0,1,2,3,4,5} )
DISTUTILS_EXT=1

inherit distutils-r1 pypi

DESCRIPTION="Python binding for curl-impersonate fork via cffi."
HOMEPAGE="
	https://pypi.org/project/curl-cffi/
	https://github.com/lexiforest/curl_cffi
"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"
#PROPERTIES="test_network"

# yt-dlp hardcodes the range of curl_cffi versions it will import and silently
# disables --impersonate when the installed version is outside it. Support for
# 0.16.x landed in yt-dlp 2026.08.19; older yt-dlp degrades with no error.
# Re-check this bound against yt_dlp/networking/_curlcffi.py on every bump.
RDEPEND="!<net-misc/yt-dlp-2026.08.19
	dev-python/cffi[${PYTHON_USEDEP}]
	dev-python/certifi[${PYTHON_USEDEP}]
	>=net-misc/curl-impersonate-1.0.0"

PATCHES=( "${FILESDIR}/${PN}-0001-system-libs.patch" )

EPYTEST_PLUGINS=( pytest-asyncio )
distutils_enable_tests pytest

EPYTEST_IGNORE=(
	# litestar module required
	tests/pro
	tests/threads/test_eventlet.py
	tests/threads/test_gevent.py
	# proxy module required
	tests/unittest
)
src_prepare() {
	# Upstream still asserts the JA3 hashes curl-cffi's README advertised in
	# 0.2.1 (2023, lwthiker-era lib): a macOS Chrome 101 capture and a Safari
	# 16.x one. The lexiforest curl-impersonate fork linked here targets
	# Windows 10 for chrome101/edge101 and ships a corrected Safari
	# 15.5-on-macOS-12.4 signature (tests/signatures/*.yaml), which our lib
	# reproduces byte-exact. Upstream CI never runs these tests (cibuildwheel
	# runs tests/unittest only), so the expectations went stale. Re-check the
	# hashes against curl-impersonate's signature DB on every bump.
	sed -i \
		-e 's|53ff64ddf993ca882b70e1c82af5da49|cd08e31494f9531f560d64c695473da9|g' \
		-e 's|8468a1ef6cb71b13e1eef8eadf786f7d|773906b0efdefa24a7f2b8eb6985bf37|g' \
		tests/integration/test_fingerprints.py || die
	distutils-r1_src_prepare
}

python_test() {
	rm -rf curl_cffi || die
	epytest
}
