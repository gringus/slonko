# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# TODO
# Peroper systemd handling
# GUI support
# WebApp support

EAPI=8

inherit cmake

DESCRIPTION="Local AI server: optimized LLM inference on AMD NPU + GPU"
HOMEPAGE="
	https://lemonade-server.ai/
	https://github.com/lemonade-sdk/lemonade
"

SRC_URI="https://github.com/lemonade-sdk/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"

RDEPEND="
	acct-group/lemonade
	acct-user/lemonade
	>=app-arch/zstd-1.5.5
	>=dev-cpp/cpp-httplib-0.26.0
	>=net-libs/libwebsockets-4.3.3
	>=net-libs/mbedtls-3.0
	>=net-misc/curl-8.5.0
	sys-libs/libcap
	systemd? ( sys-apps/systemd:= )
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-cpp/cli11-2.4.2
	>=dev-cpp/nlohmann_json-3.11.3
	x11-libs/libdrm
	virtual/pkgconfig
"

src_prepare() {
	cmake_src_prepare

	# We have mbedcrypto-3 instead of mbedcrypto
	sed -i \
		-e 's|pkg_check_modules(MBEDCRYPTO QUIET mbedcrypto)|pkg_check_modules(MBEDCRYPTO QUIET mbedcrypto-3)|' \
		src/cpp/cli/CMakeLists.txt || die
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_WEB_APP=OFF
		-DBUILD_TAURI_APP=OFF
		-DUSE_SYSTEM_HTTPLIB=ON
		-DHTTPLIB_LINK_LIBRARIES=cpp-httplib
	)
	cmake_src_configure
}
