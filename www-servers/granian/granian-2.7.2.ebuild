# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CARGO_OPTIONAL=yes
DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=maturin
PYTHON_COMPAT=( python3_{10..14} )

CRATES="
	aes@0.8.4
	anyhow@1.0.102
	arc-swap@1.8.2
	atomic-waker@1.1.2
	autocfg@1.5.0
	base64@0.22.1
	base64ct@1.8.3
	bitflags@2.11.0
	block-buffer@0.10.4
	block-padding@0.3.3
	bytes@1.11.1
	cbc@0.1.2
	cc@1.2.56
	cfg-if@1.0.4
	ciborium-io@0.2.2
	ciborium-ll@0.2.2
	ciborium@0.2.2
	cipher@0.4.4
	const-oid@0.9.6
	cpufeatures@0.2.17
	crossbeam-channel@0.5.15
	crossbeam-utils@0.8.21
	crunchy@0.2.4
	crypto-common@0.1.7
	data-encoding@2.10.0
	der@0.7.10
	digest@0.10.7
	doctest-file@1.0.0
	either@1.15.0
	encoding_rs@0.8.35
	equivalent@1.0.2
	errno@0.3.14
	find-msvc-tools@0.1.9
	fnv@1.0.7
	futures-channel@0.3.32
	futures-core@0.3.32
	futures-executor@0.3.32
	futures-io@0.3.32
	futures-macro@0.3.32
	futures-sink@0.3.32
	futures-task@0.3.32
	futures-util@0.3.32
	futures@0.3.32
	generic-array@0.14.7
	getrandom@0.2.17
	getrandom@0.3.4
	h2@0.4.13
	half@2.7.1
	hashbrown@0.16.1
	heck@0.5.0
	hmac@0.12.1
	http-body-util@0.1.3
	http-body@1.0.1
	http@1.4.0
	httparse@1.10.1
	httpdate@1.0.3
	hyper-util@0.1.20
	hyper@1.8.1
	indexmap@2.13.0
	indoc@2.0.7
	inout@0.1.4
	itertools@0.14.0
	itoa@1.0.17
	libc@0.2.182
	libmimalloc-sys@0.1.44
	lock_api@0.4.14
	log@0.4.29
	memchr@2.8.0
	memoffset@0.9.1
	mimalloc@0.1.48
	mime@0.3.17
	mime_guess@2.0.5
	mio@1.1.1
	ntapi@0.4.3
	objc2-core-foundation@0.3.2
	objc2-io-kit@0.3.2
	once_cell@1.21.3
	parking_lot@0.12.5
	parking_lot_core@0.9.12
	pbkdf2@0.12.2
	pem@3.0.6
	percent-encoding@2.3.2
	pin-project-lite@0.2.16
	pin-utils@0.1.0
	pkcs5@0.7.1
	pkcs8@0.10.2
	portable-atomic@1.13.1
	ppv-lite86@0.2.21
	proc-macro2@1.0.106
	pyo3-build-config@0.27.2
	pyo3-ffi@0.27.2
	pyo3-macros-backend@0.27.2
	pyo3-macros@0.27.2
	pyo3@0.27.2
	python3-dll-a@0.2.14
	quote@1.0.44
	r-efi@5.3.0
	rand@0.9.2
	rand_chacha@0.9.0
	rand_core@0.6.4
	rand_core@0.9.5
	recvmsg@1.0.0
	redox_syscall@0.5.18
	ring@0.17.14
	rustls-pemfile@2.2.0
	rustls-pki-types@1.14.0
	rustls-webpki@0.103.9
	rustls@0.23.37
	rustversion@1.0.22
	salsa20@0.10.2
	scopeguard@1.2.0
	scrypt@0.11.0
	serde@1.0.228
	serde_core@1.0.228
	serde_derive@1.0.228
	sha1@0.10.6
	sha2@0.10.9
	shlex@1.3.0
	signal-hook-registry@1.4.8
	slab@0.4.12
	smallvec@1.15.1
	socket2@0.6.2
	spki@0.7.3
	subtle@2.6.1
	syn@2.0.117
	sysinfo@0.37.2
	target-lexicon@0.13.5
	thiserror-impl@2.0.18
	thiserror@2.0.18
	tikv-jemalloc-sys@0.6.1+5.3.0-1-ge13ca993e8ccb9ba9847cc330696e02839f328f7
	tikv-jemallocator@0.6.1
	tokio-macros@2.6.0
	tokio-rustls@0.26.4
	tokio-stream@0.1.18
	tokio-tungstenite@0.28.0
	tokio-util@0.7.18
	tokio@1.49.0
	tracing-core@0.1.36
	tracing@0.1.44
	tungstenite@0.28.0
	typenum@1.19.0
	unicase@2.9.0
	unicode-ident@1.0.24
	unindent@0.2.4
	untrusted@0.9.0
	utf-8@0.7.6
	version_check@0.9.5
	wasi@0.11.1+wasi-snapshot-preview1
	wasip2@1.0.2+wasi-0.2.9
	widestring@1.2.1
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-collections@0.2.0
	windows-core@0.61.2
	windows-future@0.2.1
	windows-implement@0.60.2
	windows-interface@0.59.3
	windows-link@0.1.3
	windows-link@0.2.1
	windows-numerics@0.2.0
	windows-result@0.3.4
	windows-strings@0.4.2
	windows-sys@0.52.0
	windows-sys@0.60.2
	windows-sys@0.61.2
	windows-targets@0.52.6
	windows-targets@0.53.5
	windows-threading@0.1.0
	windows@0.61.3
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_gnullvm@0.53.1
	windows_aarch64_msvc@0.52.6
	windows_aarch64_msvc@0.53.1
	windows_i686_gnu@0.52.6
	windows_i686_gnu@0.53.1
	windows_i686_gnullvm@0.52.6
	windows_i686_gnullvm@0.53.1
	windows_i686_msvc@0.52.6
	windows_i686_msvc@0.53.1
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnu@0.53.1
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_gnullvm@0.53.1
	windows_x86_64_msvc@0.52.6
	windows_x86_64_msvc@0.53.1
	wit-bindgen@0.51.0
	zerocopy-derive@0.8.39
	zerocopy@0.8.39
	zeroize@1.8.2
"

declare -A GIT_CRATES=(
	[interprocess]='https://github.com/kotauskas/interprocess;44351c4fe88c72ead4f3b0b762c4cf45beb90841;interprocess-%commit%'
	[pyo3-log]='https://github.com/gi0baro/pyo3-log;5725d1dc79f34c6286938d3be8bcd89e540bae76;pyo3-log-%commit%'
	[tls-listener]='https://github.com/gi0baro/tls-listener;28d8a48209466324343d133414ea9af218faebb3;tls-listener-%commit%'
)

inherit cargo distutils-r1 pypi

DESCRIPTION="A Rust HTTP server for Python applications"
HOMEPAGE="
	https://github.com/emmett-framework/granian
	https://pypi.org/project/granian/
"
SRC_URI+="
	${CARGO_CRATE_URIS}
"
LICENSE="BSD"
# Dependent crate licenses
LICENSE+="
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD ISC MIT
	Unicode-3.0
"
SLOT="0"
KEYWORDS="amd64"

DOCS=( README.md )

RDEPEND="
	>=dev-python/click-8.1.0[${PYTHON_USEDEP}]
"
DEPEND="
	${RDEPEND}
"

BDEPEND="
	${RUST_DEPEND}
	test? (
		>=dev-python/httpx-0.28[${PYTHON_USEDEP}]
		>=dev-python/pytest-asyncio-0.26[${PYTHON_USEDEP}]
		>=dev-python/sniffio-1.3[${PYTHON_USEDEP}]
		>=dev-python/websockets-15.0[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest

src_unpack() {
	cargo_src_unpack
}

python_test() {
	rm -rf granian || die
	epytest
}
