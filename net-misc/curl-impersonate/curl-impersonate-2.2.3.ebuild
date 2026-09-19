# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Modeled after net-misc/curl (configure-driven, USE-switchable protocols), but
# per the fork's CMakeLists.txt the following are hardcoded and NOT switchable:
# - always on:  BoringSSL TLS (fork-patched), HTTP/2, HTTP/3 + proxy-HTTP/3
#               (ngtcp2/nghttp3, fork-patched), ECH, IPv6, c-ares resolver
#               (threaded resolver off), brotli (fork-patched), zstd,
#               websockets, alt-svc, hsts, httpsrr, ssls-export,
#               USE_CURL_SSLKEYLOGFILE
# - always off: libpsl, LDAP/LDAPS, libssh2, built-in manual
# Only idn (USE_LIBIDN2) is an upstream option; protocols, kerberos, gsasl and
# debug stay at curl defaults, so they are exposed as USE flags like net-misc/curl.
# Fork-patched dependencies (brotli, boringssl, nghttp3, ngtcp2) are built
# statically in ${S}/deps or the boringssl source dir; unpatched ones (zlib,
# zstd, nghttp2, c-ares) come from the system.

inherit autotools cmake flag-o-matic multiprocessing

DESCRIPTION="An active fork of curl-impersonate with more versions and build targets"
HOMEPAGE="https://github.com/lexiforest/curl-impersonate"
BORINGSSL_SHA="156c7b75ae9b8c3b3f847acf264f17594c3859fb"
CURL_VERSION="curl-8_22_0"
# Needed for HTTP/3. Versions + patches are what the fork's CMakeLists pins;
# curl.patch uses APIs (nghttp3_settings_entry, ngtcp2_transport_params_raw) that
# only exist after patches/nghttp3.patch and patches/ngtcp2.patch are applied.
NGHTTP3_PV="1.15.0"
NGTCP2_PV="1.20.0"
# brotli is fork-patched (patches/brotli.patch), so it cannot be a system dep.
BROTLI_PV="1.2.0"
SRC_URI="https://github.com/lexiforest/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/google/boringssl/archive/${BORINGSSL_SHA}.tar.gz -> boringssl-${BORINGSSL_SHA}.tar.gz
	https://github.com/curl/curl/archive/${CURL_VERSION}.tar.gz -> ${CURL_VERSION//_/.}.tar.gz
	https://github.com/google/brotli/archive/refs/tags/v${BROTLI_PV}.tar.gz -> brotli-${BROTLI_PV}.tar.gz
	https://github.com/ngtcp2/nghttp3/releases/download/v${NGHTTP3_PV}/nghttp3-${NGHTTP3_PV}.tar.xz
	https://github.com/ngtcp2/ngtcp2/releases/download/v${NGTCP2_PV}/ngtcp2-${NGTCP2_PV}.tar.xz"

# MIT: the fork, brotli, nghttp3, ngtcp2; curl: the embedded curl code;
# Apache-2.0: the pinned boringssl (relicensed upstream, per its LICENSE).
LICENSE="MIT"
LICENSE+=" curl Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+clients debug +ftp +gopher +idn +imap kerberos +pop3 sasl-scram +smtp +telnet +tftp"

# Defaults mirror the fork's release builds: all protocols, idn on (Linux),
# kerberos/gsasl off (curl's cmake defaults, not set by the fork).
# nghttp2: fork pins <=1.64 — 1.65 removed RFC 7540 priority, making
# nghttp2_submit_priority (used by curl.patch's legacy-priority impersonation
# profiles) a no-op. System nghttp2 is a deliberate shared dep, so >=1.65
# silently loses legacy priority. https://nghttp2.org/blog/2025/03/02/nghttp2-v1-65-0/
RDEPEND="
	app-misc/ca-certificates
	>=net-dns/c-ares-1.16.0:=
	idn? ( net-dns/libidn2:= )
	kerberos? ( virtual/krb5 )
	net-libs/nghttp2:=
	sasl-scram? ( net-misc/gsasl )
	virtual/zlib
	app-arch/zstd:=
"
DEPEND="${RDEPEND}"
# The autotools/cmake eclasses also set BDEPEND (autoconf-automake-libtool,
# ninja, >=cmake floor); PMS 10.2 accumulates eclass-defined values after the
# ebuild's own, so a plain assignment keeps them.
BDEPEND="virtual/pkgconfig"

DOCS=( README.md )

# Skips the fork's CMake superbuild: builds the fork-patched deps statically
# (nghttp3/ngtcp2 against the same boringssl, so HTTP/3 never pulls a second,
# system TLS library into the process), then curl with the patches, mirroring
# the fork's configure flags.

src_prepare() {
	# The fork's own patches ship inside the source tarball under patches/.
	mv "${WORKDIR}/brotli-${BROTLI_PV}" "${S}/" || die
	pushd "brotli-${BROTLI_PV}" || die
	eapply ../patches/brotli.patch
	popd || die
	mv "${WORKDIR}/boringssl-${BORINGSSL_SHA}" "${S}/" || die
	pushd "boringssl-${BORINGSSL_SHA}" || die
	eapply ../patches/boringssl.patch
	# cmake_src_prepare uses $PWD as CMAKE_USE_DIR; keeps cmake_src_configure/compile
	# pointed at the boringssl tree (and gives it the usual eclass QA treatment).
	cmake_src_prepare
	popd || die
	mv "${WORKDIR}/curl-${CURL_VERSION}" "${S}/${CURL_VERSION}" || die
	pushd "${CURL_VERSION}" || die
	eapply ../patches/curl.patch
	eautoreconf
	popd || die
	mv "${WORKDIR}/nghttp3-${NGHTTP3_PV}" "${WORKDIR}/ngtcp2-${NGTCP2_PV}" "${S}/" || die
	# these two are NOT vanilla: they add the APIs curl.patch calls (settings_entry,
	# transport_params_raw). Same versions the fork's CMakeLists ExternalProject pins.
	pushd "nghttp3-${NGHTTP3_PV}" || die
	eapply ../patches/nghttp3.patch
	popd || die
	pushd "ngtcp2-${NGTCP2_PV}" || die
	eapply ../patches/ngtcp2.patch
	popd || die
	default
}

src_configure() {
	pushd "boringssl-${BORINGSSL_SHA}" || die
	# boringssl hardcodes -Werror via add_compile_options (C_CXX_WARNINGS), which
	# bypasses CMAKE_*_FLAGS — a -Wno-error flag can't reach it, so strip it here.
	sed -re 's|-Werror||g' -i CMakeLists.txt || die
	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=OFF
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
		# only libssl/libcrypto are consumed; skips the gtest/benchmark test build
		-DBUILD_TESTING=OFF
	)
	cmake_src_configure
	popd || die
}

src_compile() {
	# Staging prefix for the embedded static libs; curl's --with-<lib> probes look
	# in <path>/lib, so force libdir to lib (not lib64).
	local deps="${S}/deps"
	local bs="${S}/boringssl-${BORINGSSL_SHA}"
	local jobs="$(get_makeopts_jobs)"

	# Fork's superbuild targets ssl+crypto only; those are the only libs we copy.
	pushd "boringssl-${BORINGSSL_SHA}" || die
	cmake_src_compile ssl crypto
	popd || die
	mkdir "boringssl-${BORINGSSL_SHA}/lib" || die
	cp "boringssl-${BORINGSSL_SHA}_build"/*.a "boringssl-${BORINGSSL_SHA}/lib" || die

	# Shared embed policy for the static deps (same flags the fork's CMakeLists
	# passes per dep): PIC, no distro build type, staged into ${deps}.
	local -a dep_cmake=(
		-DCMAKE_BUILD_TYPE=None
		-DCMAKE_INSTALL_PREFIX="${deps}"
		-DCMAKE_INSTALL_LIBDIR="${deps}/lib"
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON
	)
	build_dep() {
		pushd "$1" || die
		shift
		cmake -S . -B build "${dep_cmake[@]}" "$@" || die
		cmake --build build -j "${jobs}" || die
		cmake --install build || die
		popd || die
	}

	# brotli: same flags the fork's CMakeLists passes
	build_dep "brotli-${BROTLI_PV}" \
		-DBUILD_SHARED_LIBS=OFF \
		-DBROTLI_BUILD_TOOLS=OFF

	build_dep "nghttp3-${NGHTTP3_PV}" \
		-DENABLE_LIB_ONLY=ON -DENABLE_SHARED_LIB=OFF -DENABLE_STATIC_LIB=ON \
		-DBUILD_TESTING=OFF
	# fork's guard: patched header must win over any generated copy
	cp "nghttp3-${NGHTTP3_PV}/lib/includes/nghttp3/nghttp3.h" \
		"${deps}/include/nghttp3/nghttp3.h" || die
	grep -q nghttp3_settings_entry "${deps}/include/nghttp3/nghttp3.h" || \
		die "nghttp3.patch did not apply (no nghttp3_settings_entry)"

	build_dep "ngtcp2-${NGTCP2_PV}" \
		-DENABLE_LIB_ONLY=ON -DENABLE_SHARED_LIB=OFF -DENABLE_STATIC_LIB=ON \
		-DENABLE_OPENSSL=OFF -DENABLE_BORINGSSL=ON -DENABLE_PICOTLS=OFF \
		-DENABLE_WOLFSSL=OFF -DENABLE_GNUTLS=OFF \
		-DBORINGSSL_INCLUDE_DIR="${bs}/include" \
		-DBORINGSSL_LIBRARIES="${bs}/lib/libssl.a;${bs}/lib/libcrypto.a" \
		-DBUILD_TESTING=OFF
	grep -q ngtcp2_transport_params_raw "${deps}/include/ngtcp2/ngtcp2.h" || \
		die "ngtcp2.patch did not apply (no ngtcp2_transport_params_raw)"

	pushd "${CURL_VERSION}" || die
	# This configure has to be here to see the libraries just built
	# Banner says curl-impersonate/${PV} instead of /local (macro is #ifndef-guarded,
	# cmake superbuild passes it the same way). Backslash-escaped quotes are
	# required: plain quotes get stripped by shell quote removal somewhere in the
	# make pipeline (macro becomes a bare 2.2.3 number -> compile error), while
	# gcc consumes \"2.2.3\" as a string; the "missing terminating" warning it
	# prints is cosmetic.
	append-cppflags "-DCURL_IMPERSONATE_VERSION=\\\"${PV}\\\""
	# Pin the C++ runtime to libstdc++ to match the static boringssl/brotli
	# objects (linked via -lstdc++ below); clang's default libc++ would mix
	# runtimes in one binary.
	append-cxxflags -stdlib=libstdc++
	# boringssl is C++ but curl links as C, so -lstdc++ can only enter via
	# LDFLAGS — which lands BEFORE configure's conftest objects. GNU ld's
	# --as-needed then drops it (nothing references C++ symbols yet) and the
	# SSL_connect probe fails with undefined __cxa_* / std::* refs. mold is
	# order-independent and hides this. Push/pop as-needed around it so only
	# -lstdc++ is exempt.
	append-ldflags "-Wl,--push-state,--no-as-needed" "-lstdc++" "-Wl,--pop-state"
	econf \
		$(use_enable debug) \
		$(use_enable ftp) \
		$(use_enable gopher) \
		$(use_enable imap) \
		$(use_enable pop3) \
		$(use_enable smtp) \
		$(use_enable telnet) \
		$(use_enable tftp) \
		--with-brotli="${deps}" \
		--with-ca-bundle="${EPREFIX}/etc/ssl/certs/ca-certificates.crt" \
		--with-nghttp2="${EPREFIX}/usr/$(get_libdir)" \
		--with-nghttp3="${deps}" \
		--with-ngtcp2="${deps}" \
		--with-openssl="${S}/boringssl-${BORINGSSL_SHA}" \
		$(use_with idn libidn2) \
		$(use_with kerberos gssapi "${EPREFIX}/usr") \
		$(use_with sasl-scram libgsasl) \
		--with-zlib \
		--with-zstd \
		--enable-ares \
		--disable-threaded-resolver \
		--enable-ech \
		--enable-httpsrr \
		--enable-ssls-export \
		--enable-ipv6 \
		--enable-proxy-http3 \
		--enable-websockets \
		--disable-ldap \
		--disable-ldaps \
		--disable-manual \
		--disable-static \
		--without-libpsl \
		--without-libssh2 \
		# -pthread: boringssl; -lstdc++: boringssl is C++ (runtime pinned above)
		LIBS="-pthread -lstdc++" \
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
	# Headers would collide with net-misc/curl; the shared lib is the drop-in part.
	rm -fR "${D}/usr/share/man" "${D}/usr/share/aclocal" "${D}/usr/include" || die
	find "${ED}" -name '*.la' -delete || die
	popd || die
	if use clients; then
		local bn i
		for i in bin/curl_*; do
			bn=${i##*/}
			newbin "$i" "${bn//_/-}"
		done
	fi
	einstalldocs
}

pkg_postinst() {
	if use debug; then
		ewarn "USE=debug has been selected, enabling debug codepaths and making cURL extra verbose."
		ewarn "Use this _only_ for testing. Debug builds should _not_ be used in anger."
		ewarn "hic sunt dracones; you have been warned."
	fi
}
