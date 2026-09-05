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
EPYTEST_DESELECT=(
	# Network required
	tests/integration/test_fingerprints.py::test_not_impersonate
	tests/integration/test_fingerprints.py::test_impersonate
	tests/integration/test_fingerprints.py::test_impersonate_edge
	tests/integration/test_fingerprints.py::test_impersonate_safari
	tests/integration/test_httpbin.py::test_gzip
	tests/integration/test_httpbin.py::test_brotli
	tests/integration/test_httpbin.py::test_redirect_n
	tests/integration/test_httpbin.py::test_relative_redirect_n
	tests/integration/test_httpbin.py::test_imperonsate_default_headers
	tests/integration/test_httpbin.py::test_curl_options
	tests/integration/test_httpbin.py::test_http_version
	tests/integration/test_real_world.py::test_post_with_no_body
	tests/integration/test_response_class.py::test_default_response
	tests/integration/test_response_class.py::test_custom_response
)

python_test() {
	rm -rf curl_cffi || die
	epytest
}
