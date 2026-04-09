# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Google's PDF rendering engine (standalone source build)"
HOMEPAGE="https://pdfium.googlesource.com"

inherit git-r3 ninja-utils

CHROMIUM_VERSION="147.0.${PV}.0"
TEST_FONT="cd96fc55dc243f6c6f4cb63ad117cad6cd48dceb"

EGIT_REPO_URI="https://pdfium.googlesource.com/pdfium.git"
EGIT_BRANCH="chromium/${PV}"
EGIT_COMMIT="79d84a59fb337f5ae4c1c9fee60677c29a310f46"

SRC_URI="
	https://raw.githubusercontent.com/chromium/chromium/${CHROMIUM_VERSION}/tools/generate_shim_headers/generate_shim_headers.py
	test? ( https://chromium-fonts.storage.googleapis.com/${TEST_FONT} -> chromium-testfonts-${TEST_FONT}.tar.gz )"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

BDEPEND="
	dev-build/gn
	test? (
		dev-cpp/gtest
		dev-cpp/simdutf
	)
"
DEPEND="
	dev-cpp/fast_float
	dev-libs/glib
	dev-libs/icu
	media-libs/freetype
	media-libs/harfbuzz
	media-libs/lcms
	media-libs/libjpeg-turbo
	media-libs/libpng
	media-libs/openjpeg
	virtual/zlib
"
RDEPEND="${DEPEND}"
PATCHES=(
	"${FILESDIR}"/public_headers.patch
	"${FILESDIR}"/shared_library.patch
)

CHROMIUM_REPO="https://chromium.googlesource.com"

src_unpack() {
	# pdfium
	git-r3_src_unpack

	EGIT_BRANCH=""

	# build
	EGIT_REPO_URI="${CHROMIUM_REPO}"/chromium/src/build
	EGIT_CHECKOUT_DIR="${S}"/build
	EGIT_COMMIT=$(awk -F\' '$2 == "build_revision" && NF == 5 {print $4}' "${S}"/DEPS)
	git-r3_src_unpack

	# abseil-cpp
	EGIT_REPO_URI="${CHROMIUM_REPO}"/chromium/src/third_party/abseil-cpp
	EGIT_CHECKOUT_DIR="${S}"/third_party/abseil-cpp
	EGIT_COMMIT=$(awk -F\' '$2 == "abseil_revision" && NF == 5 {print $4}' "${S}"/DEPS)
	git-r3_src_unpack

	if use test; then
		# gtest
		EGIT_REPO_URI="${CHROMIUM_REPO}"/external/github.com/google/googletest
		EGIT_CHECKOUT_DIR="${S}"/third_party/googletest/src
		EGIT_COMMIT=$(awk -F\' '$2 == "gtest_revision" && NF == 5 {print $4}' "${S}"/DEPS)
		git-r3_src_unpack

		# test_fonts
		EGIT_REPO_URI="${CHROMIUM_REPO}"/chromium/src/third_party/test_fonts
		EGIT_CHECKOUT_DIR="${S}"/third_party/test_fonts
		EGIT_COMMIT=$(awk -F\' '$2 == "test_fonts_revision" && NF == 5 {print $4}' "${S}"/DEPS)
		git-r3_src_unpack

		tar xf "${DISTDIR}"/chromium-testfonts-${TEST_FONT}.tar.gz -C "${S}"/third_party/test_fonts || die

	else
		# Remove test dependencies
		sed -i \
			-e '/\/\/third_party\/test_fonts/d' \
			-e '/\/\/third_party\/simdutf/d' \
			"${S}"/testing/BUILD.gn || die
	fi

	# generate_shim_headers
	mkdir -p "${S}"/tools/generate_shim_headers || die
	cp "${DISTDIR}"/generate_shim_headers.py "${S}"/tools/generate_shim_headers || die
}

src_prepare() {
	default

	# Unbundle packages
	local unbundle=(
		icu
		simdutf
	)

	for pkg in "${unbundle[@]}"; do
		mkdir -p third_party/"${pkg}" || die
		ln -sf "${S}/build/linux/unbundle/${pkg}.gn" "${S}/third_party/${pkg}/BUILD.gn" || die
	done

	# Use system fast_float
	mkdir -p third_party/fast_float/src/include/
	ln -sf /usr/include/fast_float third_party/fast_float/src/include/
}

src_configure() {
	echo "build_with_chromium = false" > "${S}"/build/config/gclient_args.gni

	# Define GN build arguments
	local gn_args=(
		"clang_use_chrome_plugins=false"
		"is_clang=false"
		"use_lld=false"
		"is_debug=false"
		"pdf_enable_v8=false"
		"pdf_enable_xfa=false"
		"is_component_build=false"
		"pdf_is_standalone=true"
		"treat_warnings_as_errors=false"
		"use_custom_libcxx=false"
		"use_glib=true"
		"pdf_use_partition_alloc=false"
		"pdf_use_skia=false"
		"use_sysroot=false"
		"use_system_freetype=true"
		"pdf_bundle_freetype=false"
		"use_remoteexec=false"
		"use_system_harfbuzz=true"
		"use_system_lcms2=true"
		"use_system_libjpeg=true"
		"use_system_libopenjpeg2=true"
		"use_system_libpng=true"
		"use_system_zlib=true"
	)
	# Generate build files using GN
	gn gen out/Release --args="${gn_args[*]}" || die
}

src_compile() {
	local -a targets=( pdfium )
	if use test ; then
		targets+=( pdfium_unittests )
	fi

	eninja -C out/Release ${targets[@]} || die
}

src_test() {
	local skip_tests=(
		# May fail with system zlib (produces different results)
		FlateModule.Encode
		# May fail with use_custom_libcxx=false
		RetainPtr.SetContains
	)
	local test_filter="-$(IFS=:; printf '%s' "${skip_tests[*]}")"

	out/Release/pdfium_unittests --gtest_filter="${test_filter}" || die "Tests failed!"
}

src_install() {
	# Manual installation of headers and library
	dolib.so out/Release/libpdfium.so

	insinto /usr/include/pdfium
	doins public/*.h
	insinto /usr/include/pdfium/cpp
	doins public/cpp/*.h

	dodir /usr/$(get_libdir)/pkgconfig
	sed \
		-e "s/@VERSION@/${CHROMIUM_VERSION}/" \
		"${FILESDIR}"/libpdfium.pc.in > "${ED}/usr/$(get_libdir)/pkgconfig/libpdfium.pc" || die
}
