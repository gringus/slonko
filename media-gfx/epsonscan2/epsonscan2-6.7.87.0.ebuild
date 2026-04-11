# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PROG="${P}-1"

DESCRIPTION="Epson scanner management utility"
HOMEPAGE="https://download.ebz.epson.net/dsc/search/01/search/?OSC=LX"
SRC_URI="https://download-center.epson.com/f/module/1ef33427-5366-4a18-9726-c44197b04301/${MY_PROG}.src.tar.gz"
S="${WORKDIR}/${MY_PROG}"

inherit cmake desktop flag-o-matic udev

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	dev-libs/boost
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtwidgets:5
	media-gfx/sane-backends
	media-libs/libharu
	media-libs/libjpeg-turbo:=
	media-libs/libpng
	media-libs/tiff
	virtual/libusb:1
	virtual/zlib:=
"
RDEPEND="${DEPEND}"
RESTRICT="mirror fetch"

PATCHES=(
	"${FILESDIR}/0002-Fix-crash.patch"
	"${FILESDIR}/0003-Use-XDG-open-to-open-the-directory.patch"
	"${FILESDIR}/0004-Fix-a-crash-on-an-OOB-container-access.patch"
	"${FILESDIR}/0005-Fix-folder-creation-crash.patch"
	"${FILESDIR}/0006-Fix-desktop-deprecated.patch"
)

pkg_nofetch() {
	einfo "Please download ${SRC_URI}"
	einfo "manually using your browser and move it to your distfiles directory."
}

src_prepare() {
	sed -i -e '/create_symlink/d' CMakeLists.txt || die
	# Unbundle libharu and zlib
	rm -rf thirdparty/{HaruPDF,zlib}
	sed -i \
		-e '/thirdparty\/HaruPDF/d' \
		-e '/thirdparty\/zlib/d' \
		-e 's|^\([[:blank:]]*\)\(usb-1.0\)|\1\2\n\1hpdf\n\1z|' \
		src/Controller/CMakeLists.txt || die

	# Boost 1.87 compatibility (BOOST_NO_CXX11_RVALUE_REFERENCES should be set by Boost)
	find . -name CMakeLists.txt -exec sed -e '/add_definitions.*DBOOST_NO_CXX11_RVALUE_REFERENCES/d' -i {} \;
	find . \( -name "*.h" -o -name "*.hpp" -o -name "*.cpp" \) \
		-exec sed -e '/#define.*BOOST_NO_CXX11_RVALUE_REFERENCES/d' -i {} \;

	# Fix compilation failure with GCC 15
	append-cxxflags $(test-flags-CXX -Wno-template-body)
	sed -i '/#include/ i #include <cmath>' 'src/Controller/Src/Filter/GrayToMono.hpp' || die

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DEPSON_OCR_INSTALL_PATH=/usr/$(get_libdir)/epsonscan2-ocr
		-DQT_VERSION_MAJOR=5
	)
	export EPSON_VERSION=${PV}
	cmake_src_configure
}

src_install() {
	cmake_src_install
	# Sane symlinks
	dosym ../epsonscan2/libsane-epsonscan2.so /usr/$(get_libdir)/sane/libsane-epsonscan2.so
	dosym ../epsonscan2/libsane-epsonscan2.so /usr/$(get_libdir)/sane/libsane-epsonscan2.so.1
	dosym ../epsonscan2/libsane-epsonscan2.so /usr/$(get_libdir)/sane/libsane-epsonscan2.so.1.0.0
	# Desktop icon
	domenu desktop/rpm/x86_64/epsonscan2.desktop
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
