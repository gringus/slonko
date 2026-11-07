# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Adapted from ::stuff (istitov)

EAPI=8

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

RUST_MIN_VER="1.85.0"
CRATES="
	aho-corasick@1.1.5
	bit-set@0.8.0
	bit-vec@0.8.0
	bstr@1.13.1
	fancy-regex@0.19.0
	heck@0.5.0
	libc@0.2.189
	memchr@2.8.3
	once_cell@1.21.4
	portable-atomic@1.15.0
	proc-macro2@1.0.107
	pyo3-build-config@0.29.2
	pyo3-ffi@0.29.2
	pyo3-macros-backend@0.29.2
	pyo3-macros@0.29.2
	pyo3@0.29.2
	quote@1.0.47
	regex-automata@0.4.18
	regex-syntax@0.8.11
	regex@1.13.1
	rustc-hash@2.1.3
	serde_core@1.0.229
	serde_derive@1.0.229
	syn@2.0.119
	syn@3.0.3
	target-lexicon@0.13.5
	unicode-ident@1.0.24
"

inherit cargo distutils-r1 pypi

DESCRIPTION="A fast BPE tokeniser for use with OpenAI's models"
HOMEPAGE="
	https://github.com/openai/tiktoken
	https://pypi.org/project/tiktoken/
"
SRC_URI+="
	${CARGO_CRATE_URIS}
	test? (
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe -> tiktoken-gpt2-vocab.bpe
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json -> tiktoken-gpt2-encoder.json
		https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken -> tiktoken-r50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken -> tiktoken-p50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken -> tiktoken-cl100k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken -> tiktoken-o200k_base.tiktoken
	)
"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+=" Apache-2.0-with-LLVM-exceptions MIT Unicode-3.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/regex[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
"
# The tests import dev-python/hypothesis directly; the encoder files the
# suite needs are pre-seeded via TIKTOKEN_CACHE_DIR in src_test.
BDEPEND="
	test? (
		dev-python/hypothesis[${PYTHON_USEDEP}]
	)
	dev-python/setuptools-rust[${PYTHON_USEDEP}]
"

# No pytest plugins are needed by the suite.
EPYTEST_PLUGINS=( )
distutils_enable_tests pytest

src_prepare() {
	default
	# hypothesis >=6.1xx injects string constants harvested from the tested
	# package's source (openai_public.py defines all the special tokens) into
	# st.text(), so the roundtrip test receives special-token text that
	# enc.encode(text) rejects by default. Encoding them as ordinary text is
	# the intended roundtrip property.
	sed -i \
		-e 's/enc\.decode(enc\.encode(text))/enc.decode(enc.encode(text, disallowed_special=()))/' \
		tests/test_encoding.py || die
}

src_test() {
	# The suite calls tiktoken.get_encoding()/encoding_for_model() for several
	# encodings, which fetch the files from openaipublic on first use.
	# Pre-seed TIKTOKEN_CACHE_DIR (filenames are sha1 of the blob URL) from
	# the distfiles so everything runs offline; tiktoken verifies the
	# expected sha256 on every cache read.
	local cache_dir="${T}"/tiktoken-cache
	mkdir -p "${cache_dir}" || die
	local entry url distfile
	while read -r entry; do
		[[ -z ${entry} ]] && continue
		url=${entry%%|*}
		distfile=${entry#*|}
		cp "${DISTDIR}/${distfile}" "${cache_dir}/$(printf '%s' "${url}" | sha1sum | awk '{print $1}')" || die
	done <<-EOF
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe|tiktoken-gpt2-vocab.bpe
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json|tiktoken-gpt2-encoder.json
		https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken|tiktoken-r50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken|tiktoken-p50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken|tiktoken-cl100k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken|tiktoken-o200k_base.tiktoken
	EOF
	local -x TIKTOKEN_CACHE_DIR="${cache_dir}"

	distutils-r1_src_test
}

python_test() {
	rm -rf tiktoken || die
	epytest
}
