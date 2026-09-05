# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools cmake flag-o-matic

DESCRIPTION="An active fork of curl-impersonate with more versions and build targets."
HOMEPAGE="https://github.com/lexiforest/curl-impersonate"
BORINGSSL_SHA="156c7b75ae9b8c3b3f847acf264f17594c3859fb"
CURL_VERSION="curl-8_21_0"
# Needed for HTTP/3. Versions + patches are what the fork's CMakeLists pins;
# curl.patch uses APIs (nghttp3_settings_entry, ngtcp2_transport_params_raw) that
# only exist after patches/nghttp3.patch and patches/ngtcp2.patch are applied.
NGHTTP3_PV="1.15.0"
NGTCP2_PV="1.20.0"
SRC_URI="https://github.com/lexiforest/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/google/boringssl/archive/${BORINGSSL_SHA}.tar.gz -> boringssl-${BORINGSSL_SHA}.tar.gz
	https://github.com/curl/curl/archive/${CURL_VERSION}.tar.gz -> ${CURL_VERSION//_/.}.tar.gz
	https://github.com/ngtcp2/nghttp3/releases/download/v${NGHTTP3_PV}/nghttp3-${NGHTTP3_PV}.tar.xz
	https://github.com/ngtcp2/ngtcp2/releases/download/v${NGTCP2_PV}/ngtcp2-${NGTCP2_PV}.tar.xz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="clients"

DEPEND="app-arch/brotli:=
	dev-libs/nss:=
	llvm-runtimes/libcxx:=
	net-libs/nghttp2:=
	app-arch/zstd:=
	net-libs/libpsl
	virtual/zlib"
RDEPEND="${DEPEND}"
BDEPEND="dev-build/ninja
	dev-build/cmake"

DOCS=( README.md )

# This package is cURL built with boringssl with a few patches (both in cURL and boringssl). This
# ebuild skips over curl-impersonate's not so great autotools use and just builds boringssl then
# cURL with the patches. nghttp3 and ngtcp2 are built statically against the same boringssl so
# that curl gets HTTP/3 without linking a second, system TLS library into the process.

src_prepare() {
	mv "${WORKDIR}/boringssl-${BORINGSSL_SHA}" "${S}/" || die
	pushd "boringssl-${BORINGSSL_SHA}" &>/dev/null || die
	eapply ../patches/boringssl.patch
	touch .patched || die
	cmake_src_prepare
	popd &>/dev/null || die
	mv "${WORKDIR}/curl-${CURL_VERSION}" "${S}/${CURL_VERSION}" || die
	pushd "${CURL_VERSION}" &>/dev/null || die
	eapply ../patches/curl.patch
	eautoreconf
	touch .patched-chrome || die
	popd &>/dev/null || die
	mv "${WORKDIR}/nghttp3-${NGHTTP3_PV}" "${WORKDIR}/ngtcp2-${NGTCP2_PV}" "${S}/" || die
	# these two are NOT vanilla: they add the APIs curl.patch calls (settings_entry,
	# transport_params_raw). Same versions the fork's CMakeLists ExternalProject pins.
	pushd "nghttp3-${NGHTTP3_PV}" &>/dev/null || die
	eapply ../patches/nghttp3.patch
	popd &>/dev/null || die
	pushd "ngtcp2-${NGTCP2_PV}" &>/dev/null || die
	eapply ../patches/ngtcp2.patch
	popd &>/dev/null || die
	default
}

src_configure() {
	pushd "boringssl-${BORINGSSL_SHA}" || die
	sed -re 's|-Werror||g' -i CMakeLists.txt || die
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=OFF
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
	)
	cmake_src_configure
	popd || die
}

src_compile() {
	local h3="${S}/h3"

	pushd "boringssl-${BORINGSSL_SHA}" || die
	cmake_src_compile
	popd || die
	mkdir "boringssl-${BORINGSSL_SHA}/lib" || die
	cp "boringssl-${BORINGSSL_SHA}_build"/*.a "boringssl-${BORINGSSL_SHA}/lib" || die

	# Built with CMake against the bundled BoringSSL, mirroring the fork's CMakeLists
	# ExternalProject steps (their patches may add sources only listed in CMakeLists.txt).
	# Installed into ${S}/h3; curl's --with-nghttp3/ngtcp2 probes look in <path>/lib,
	# so force libdir to lib (not lib64).
	local bs="${S}/boringssl-${BORINGSSL_SHA}"

	pushd "nghttp3-${NGHTTP3_PV}" || die
	cmake -S . -B build \
		-DCMAKE_BUILD_TYPE=None \
		-DCMAKE_INSTALL_PREFIX="${h3}" \
		-DCMAKE_INSTALL_LIBDIR="${h3}/lib" \
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
		-DENABLE_LIB_ONLY=ON -DENABLE_SHARED_LIB=OFF -DENABLE_STATIC_LIB=ON \
		-DBUILD_TESTING=OFF || die
	cmake --build build || die
	cmake --install build || die
	# fork's guard: patched header must win over any generated copy
	cp lib/includes/nghttp3/nghttp3.h "${h3}/include/nghttp3/nghttp3.h" || die
	grep -q nghttp3_settings_entry "${h3}/include/nghttp3/nghttp3.h" || \
		die "nghttp3.patch did not apply (no nghttp3_settings_entry)"
	popd || die

	pushd "ngtcp2-${NGTCP2_PV}" || die
	cmake -S . -B build \
		-DCMAKE_BUILD_TYPE=None \
		-DCMAKE_INSTALL_PREFIX="${h3}" \
		-DCMAKE_INSTALL_LIBDIR="${h3}/lib" \
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
		-DENABLE_LIB_ONLY=ON -DENABLE_SHARED_LIB=OFF -DENABLE_STATIC_LIB=ON \
		-DENABLE_OPENSSL=OFF -DENABLE_BORINGSSL=ON -DENABLE_PICOTLS=OFF \
		-DENABLE_WOLFSSL=OFF -DENABLE_GNUTLS=OFF \
		-DBORINGSSL_INCLUDE_DIR="${bs}/include" \
		-DBORINGSSL_LIBRARIES="${bs}/lib/libssl.a;${bs}/lib/libcrypto.a" \
		-DBUILD_TESTING=OFF || die
	cmake --build build || die
	cmake --install build || die
	grep -q ngtcp2_transport_params_raw "${h3}/include/ngtcp2/ngtcp2.h" || \
		die "ngtcp2.patch did not apply (no ngtcp2_transport_params_raw)"
	popd || die

	pushd "${CURL_VERSION}" || die
	# This configure has to be here to see the libraries just built
	append-cxxflags -stdlib=libstdc++
	append-ldflags -lstdc++
	econf \
		"--with-brotli=${EPREFIX}/usr/$(get_libdir)" \
		"--with-ca-bundle=${EPREFIX}/etc/ssl/certs/ca-certificates.crt" \
		"--with-nghttp2=${EPREFIX}/usr/$(get_libdir)" \
		"--with-nghttp3=${h3}" \
		"--with-ngtcp2=${h3}" \
		"--with-openssl=${S}/boringssl-${BORINGSSL_SHA}" \
		"--with-zlib=${EPREFIX}/usr/$(get_libdir)" \
		"--with-zstd=${EPREFIX}/usr/$(get_libdir)" \
		--enable-ech \
		--enable-ipv6 \
		--disable-static \
		--enable-websockets \
		LIBS="-pthread -lbrotlidec -lstdc++" \
		USE_CURL_SSLKEYLOGFILE=true
	emake
	popd || die
}

src_install() {
	pushd "${CURL_VERSION}" || die
	emake DESTDIR="${D}" install
	if [ -f "${D}/usr/bin/wcurl" ]; then
		mv "${D}/usr/bin/wcurl" "${D}/usr/bin/w${PN}" || die
	fi
	rm -fR "${D}/usr/share/man" "${D}/usr/share/aclocal" "${D}/usr/include" \
		"${D}/usr/$(get_libdir)/lib${PN}.la" || die
	popd || die
	if use clients; then
		local bn i
		for i in bin/curl_*; do
			bn=$(basename "$i")
			newbin "$i" "${bn//_/-}"
		done
	fi
	einstalldocs
}
