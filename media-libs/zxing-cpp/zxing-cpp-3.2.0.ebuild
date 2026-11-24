# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_OPTIONAL="1"
DISTUTILS_USE_PEP517=scikit-build-core
PYTHON_COMPAT=( python3_{12..15} )

MY_PV="${PV/_/-}"
MY_P="${PN}-${MY_PV}"
AWESOME_CSS_VER="2.4.2"
inherit cmake distutils-r1

DESCRIPTION="C++ Multi-format 1D/2D barcode image processing library"
HOMEPAGE="https://github.com/zxing-cpp/zxing-cpp"
SRC_URI="https://github.com/${PN}/${PN}/releases/download/v${MY_PV}/${MY_P}.tar.gz
	doc? (
		https://github.com/jothepro/doxygen-awesome-css/archive/refs/tags/v${AWESOME_CSS_VER}.tar.gz
			-> doxygen-awesome-css-${AWESOME_CSS_VER}.gh.tar.gz
		)
	test? (
		https://github.com/zxing-cpp/zxing-cpp/releases/download/v${MY_PV}/test_samples.tar.gz
			-> ${P}-test-samples.tar.gz
		)
"
S="${WORKDIR}/${MY_P}"

LICENSE="Apache-2.0"
SLOT="0/4"
KEYWORDS="~amd64"
IUSE="doc python test tools unicode"
REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"
RESTRICT="!test? ( test )"

RDEPEND="
	>=media-libs/zint-2.16.0:=
	python? ( ${PYTHON_DEPS} )
"
DEPEND="${RDEPEND}
	dev-libs/stb
"
BDEPEND="
	doc? ( app-text/doxygen[dot] )
	python? (
		${DISTUTILS_DEPS}
		$(python_gen_cond_dep '
			>=dev-python/nanobind-2.11.0[${PYTHON_USEDEP}]
		')
	)
	test? (
		dev-cpp/gtest
		media-libs/libwebp
		python? (
			dev-python/numpy[${PYTHON_USEDEP}]
			dev-python/pillow[${PYTHON_USEDEP}]
			media-libs/opencv[python]
		)
	)
	tools? (
		media-libs/libwebp
	)
"

src_prepare() {
	mkdir "${T}/cmake" || die

	# Generate our own WebPConfig.cmake, bug #937031
	cat <<-EOF > "${T}/cmake/WebPConfig.cmake" || die
	find_package(PkgConfig REQUIRED)

	pkg_check_modules(WebP REQUIRED IMPORTED_TARGET libwebp)
	add_library(WebP::webp ALIAS PkgConfig::WebP)
	list(APPEND _cmake_import_check_targets WebP::webp )

	set(WEBP_VERSION \${WebP_VERSION})
	set(WEBP_INCLUDE_DIRS \${WebP_INCLUDE_DIR})
	set(WEBP_LIBRARIES "\${WebP_LIBRARIES}")
	EOF

	cmake_src_prepare
	if use test ; then
		ln -s "${WORKDIR}"/test/samples test/samples || die
	fi

	# Disable remote fetch
	sed -i -e '/FetchContent/,/FetchContent_GetProperties/d' docs/CMakeLists.txt || die

	if use python; then
		pushd wrappers/python > /dev/null || die
		distutils-r1_src_prepare
		popd > /dev/null || die
	fi
}

src_configure() {
	local mycmakeargs=(
		-DZXING_DEPENDENCIES=LOCAL # force find_package as REQUIRED
		# Build and install ZXingReader and ZXingWriter
		-DZXING_EXAMPLES=$(usex tools)
		-DZXING_EXAMPLES_USE_WEBP=$(usex tools)
		-DZXING_USE_BUNDLED_ZINT=OFF
		-DZXING_ENABLE_UNICODE=$(usex unicode)
		-DZXING_WRITERS=BOTH # should be kept on until revdeps are ported away from OLD
		-DZXING_DOXYGEN=$(usex doc)
		-DZXING_BLACKBOX_TESTS=$(usex test)
		-DZXING_UNIT_TESTS=$(usex test)
		-DAWESOME_CSS_DIR="${WORKDIR}/doxygen-awesome-css-${AWESOME_CSS_VER}"
	)
	if use test || use tools ; then
		mycmakeargs+=( -DWebP_DIR="${T}/cmake" )
	fi
	cmake_src_configure

	if use python; then
		pushd wrappers/python > /dev/null || die
		distutils-r1_src_configure
		popd > /dev/null || die
	fi
}

src_compile() {
	cmake_src_compile
	use doc && cmake_src_compile docs

	if use python; then
		pushd wrappers/python > /dev/null || die
		distutils-r1_src_compile
		popd > /dev/null || die
	fi
}

python_test() {
	eunittest wrappers/python
}

src_test() {
	cmake_src_test

	use python && distutils-r1_src_test
}

src_install() {
	cmake_src_install
	if use doc; then
		dodoc -r "${BUILD_DIR}"/docs/html
	fi

	if use python; then
		mv "${ED}"/usr/share/doc/${P}/README.md "${ED}"/usr/share/doc/${P}/README.cpp.md || die
		pushd wrappers/python > /dev/null || die
		distutils-r1_src_install
		popd > /dev/null || die
		mv "${ED}"/usr/share/doc/${P}/README.md "${ED}"/usr/share/doc/${P}/README.python.md || die
	fi
}
