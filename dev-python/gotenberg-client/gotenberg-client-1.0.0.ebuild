# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{10..14} )

inherit distutils-r1 optfeature pypi

DESCRIPTION="A Python client for interfacing with the Gotenberg API"
HOMEPAGE="
	https://github.com/stumpylog/gotenberg-client
	https://pypi.org/project/gotenberg-client/
"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/typing-extensions[${PYTHON_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="
	test? (
		>=dev-python/httpx-0.27[${PYTHON_USEDEP}]
	)
"

DOCS=( README.md )

EPYTEST_PLUGINS=( )
distutils_enable_tests pytest

EPYTEST_IGNORE=(
	tests/test_backend_auto.py
	tests/test_backend_niquests.py
	tests/test_backend_requests.py
	tests/test_bookmarks.py
	tests/test_common_mixins.py
	tests/test_convert_chromium_html.py
	tests/test_convert_chromium_markdown.py
	tests/test_convert_chromium_screenshots.py
	tests/test_convert_chromium_url.py
	tests/test_convert_libre_office.py
	tests/test_convert_pdf_a.py
	tests/test_embed.py
	tests/test_encrypt.py
	tests/test_flatten.py
	tests/test_health.py
	tests/test_merge.py
	tests/test_metadata.py
	tests/test_misc_stuff.py
	tests/test_rotate.py
	tests/test_split.py
	tests/test_stamp.py
	tests/test_version.py
	tests/test_watermark.py
)

pkg_postinst() {
	optfeature "httpx support" dev-python/httpx
	optfeature "magic support" dev-python/magic
	optfeature "niquests support" dev-python/niquests
	optfeature "requests support" dev-python/requests
}
