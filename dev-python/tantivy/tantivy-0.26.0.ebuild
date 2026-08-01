# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CARGO_OPTIONAL=yes
DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=maturin
PYTHON_COMPAT=( python3_{10..14} )
MY_PN="${PN}-py"

CRATES="
	aho-corasick@1.1.3
	allocator-api2@0.2.21
	android_system_properties@0.1.5
	arc-swap@1.7.1
	async-trait@0.1.89
	autocfg@1.5.0
	base64@0.22.1
	bitflags@2.9.4
	bitpacking@0.9.3
	bon-macros@3.7.2
	bon@3.7.2
	bumpalo@3.19.0
	byteorder@1.5.0
	cc@1.2.36
	census@0.4.2
	cfg-if@1.0.3
	chrono@0.4.44
	core-foundation-sys@0.8.7
	crc32fast@1.5.0
	crossbeam-channel@0.5.15
	crossbeam-deque@0.8.6
	crossbeam-epoch@0.9.18
	crossbeam-utils@0.8.21
	crunchy@0.2.4
	darling@0.21.3
	darling_core@0.21.3
	darling_macro@0.21.3
	datasketches@0.2.0
	deranged@0.5.3
	downcast-rs@2.0.2
	either@1.15.0
	equivalent@1.0.2
	erased-serde@0.4.10
	errno@0.3.13
	fastdivide@0.4.2
	fastrand@2.3.0
	find-msvc-tools@0.1.1
	fnv@1.0.7
	foldhash@0.2.0
	fs4@0.13.1
	futures-channel@0.3.32
	futures-core@0.3.32
	futures-executor@0.3.32
	futures-io@0.3.32
	futures-macro@0.3.32
	futures-sink@0.3.32
	futures-task@0.3.32
	futures-util@0.3.32
	futures@0.3.32
	getrandom@0.3.3
	hashbrown@0.16.1
	heck@0.5.0
	htmlescape@0.3.1
	iana-time-zone-haiku@0.1.2
	iana-time-zone@0.1.63
	ident_case@1.0.1
	indoc@2.0.6
	inventory@0.3.24
	itertools@0.14.0
	itoa@1.0.15
	jobserver@0.1.34
	js-sys@0.3.78
	levenshtein_automata@0.2.1
	libc@0.2.175
	linux-raw-sys@0.9.4
	log@0.4.28
	lru@0.16.4
	lz4_flex@0.13.0
	measure_time@0.9.0
	memchr@2.7.5
	memmap2@0.9.8
	memoffset@0.9.1
	minimal-lexical@0.2.1
	murmurhash32@0.3.1
	nom@7.1.3
	num-conv@0.2.0
	num-traits@0.2.19
	once_cell@1.21.3
	oneshot@0.1.13
	ordered-float@5.3.0
	ownedbytes@0.9.0
	pin-project-lite@0.2.16
	pkg-config@0.3.32
	portable-atomic@1.11.1
	powerfmt@0.2.0
	prettyplease@0.2.37
	proc-macro2@1.0.101
	pyo3-build-config@0.26.0
	pyo3-build-config@0.28.3
	pyo3-ffi@0.26.0
	pyo3-macros-backend@0.26.0
	pyo3-macros@0.26.0
	pyo3@0.26.0
	pythonize@0.26.0
	quote@1.0.40
	r-efi@5.3.0
	rayon-core@1.13.0
	rayon@1.11.0
	regex-automata@0.4.10
	regex-syntax@0.8.6
	regex@1.11.2
	rust-stemmers@1.2.0
	rustc-hash@2.1.1
	rustix@1.0.8
	rustversion@1.0.22
	serde@1.0.228
	serde_core@1.0.228
	serde_derive@1.0.228
	serde_json@1.0.149
	shlex@1.3.0
	sketches-ddsketch@0.4.0
	slab@0.4.11
	smallvec@1.15.1
	stable_deref_trait@1.2.0
	strsim@0.11.1
	syn@2.0.106
	tantivy-bitpacker@0.10.0
	tantivy-columnar@0.7.0
	tantivy-common@0.11.0
	tantivy-fst@0.5.0
	tantivy-query-grammar@0.26.0
	tantivy-sstable@0.7.0
	tantivy-stacker@0.7.0
	tantivy-tokenizer-api@0.7.0
	tantivy@0.26.0
	target-lexicon@0.13.4
	tempfile@3.21.0
	thiserror-impl@2.0.16
	thiserror@2.0.16
	time-core@0.1.8
	time-macros@0.2.27
	time@0.3.47
	typeid@1.0.3
	typetag-impl@0.2.21
	typetag@0.2.21
	unicode-ident@1.0.18
	unindent@0.2.4
	utf8-ranges@1.0.5
	uuid@1.18.1
	wasi@0.14.4+wasi-0.2.4
	wasm-bindgen-backend@0.2.101
	wasm-bindgen-macro-support@0.2.101
	wasm-bindgen-macro@0.2.101
	wasm-bindgen-shared@0.2.101
	wasm-bindgen@0.2.101
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-core@0.61.2
	windows-implement@0.60.0
	windows-interface@0.59.1
	windows-link@0.1.3
	windows-link@0.2.0
	windows-result@0.3.4
	windows-strings@0.4.2
	windows-sys@0.59.0
	windows-sys@0.60.2
	windows-targets@0.52.6
	windows-targets@0.53.3
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_gnullvm@0.53.0
	windows_aarch64_msvc@0.52.6
	windows_aarch64_msvc@0.53.0
	windows_i686_gnu@0.52.6
	windows_i686_gnu@0.53.0
	windows_i686_gnullvm@0.52.6
	windows_i686_gnullvm@0.53.0
	windows_i686_msvc@0.52.6
	windows_i686_msvc@0.53.0
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnu@0.53.0
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_gnullvm@0.53.0
	windows_x86_64_msvc@0.52.6
	windows_x86_64_msvc@0.53.0
	wit-bindgen@0.45.1
	zmij@1.0.2
	zstd-safe@7.2.4
	zstd-sys@2.0.16+zstd.1.5.7
	zstd@0.13.3
"

inherit cargo distutils-r1

DESCRIPTION="Official Python bindings for the Tantivy search engine"
HOMEPAGE="
	https://github.com/quickwit-oss/tantivy-py
	https://pypi.org/project/tantivy/
"
SRC_URI="
	https://github.com/quickwit-oss/${MY_PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.gh.tar.gz
	${CARGO_CRATE_URIS}
"
S="${WORKDIR}/${MY_PN}-${PV}"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions MIT Unicode-3.0 ZLIB
"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	${RUST_DEPEND}
	>=dev-util/maturin-1.9.3[${PYTHON_USEDEP}]
	<dev-util/maturin-2.0.0[${PYTHON_USEDEP}]
	test? (
		dev-python/mktestdocs[${PYTHON_USEDEP}]
	)

"

distutils_enable_tests pytest

src_unpack() {
	cargo_src_unpack
}

python_test() {
	rm -rf tantivy || die
	epytest
}
