# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 slonko-test

DESCRIPTION="llama-index embeddings huggingface integration"
HOMEPAGE="
	https://github.com/run-llama/llama_index
	https://pypi.org/project/llama-index-embeddings-huggingface/
"
# The sdist ships no tests; pin the llama_index monorepo commit that
# carries this version (the last touching this package's pyproject).
SRC_URI="
	https://github.com/run-llama/llama_index/archive/98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27.tar.gz
		-> llama_index-98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27.gh.tar.gz
	test? (
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/config.json
			-> bge-small-en-config.json
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/config_sentence_transformers.json
			-> bge-small-en-config_sentence_transformers.json
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/modules.json
			-> bge-small-en-modules.json
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/1_Pooling/config.json
			-> bge-small-en-1_Pooling-config.json
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/sentence_bert_config.json
			-> bge-small-en-sentence_bert_config.json
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/model.safetensors
			-> bge-small-en-model.safetensors
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/tokenizer.json
			-> bge-small-en-tokenizer.json
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/tokenizer_config.json
			-> bge-small-en-tokenizer_config.json
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/special_tokens_map.json
			-> bge-small-en-special_tokens_map.json
		https://huggingface.co/BAAI/bge-small-en/resolve/2275a7bdee235e9b4f01fa73aa60d3311983cfea/vocab.txt
			-> bge-small-en-vocab.txt
	)
"
S="${WORKDIR}/llama_index-98c52d8ac8f8a89bc2d79cf1d71054b0424a9d27/llama-index-integrations/embeddings/llama-index-embeddings-huggingface"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# huggingface-hub[inference] extra pulls nothing beyond the base package.
RDEPEND="
	>=sci-ml/huggingface_hub-0.19.0
	>=dev-python/llama-index-core-0.13.0[${PYTHON_USEDEP}]
	<dev-python/llama-index-core-0.15[${PYTHON_USEDEP}]
	>=dev-python/sentence-transformers-2.6.1[${PYTHON_USEDEP}]
"

distutils_enable_tests pytest

src_test() {
	# The suite instantiates HuggingFaceEmbedding("BAAI/bge-small-en"),
	# which would fetch the model from the HF Hub on first use. The
	# wrapper passes llama-index's own cache dir (get_cache_dir()) as the
	# HF cache_dir, bypassing HF_HUB_CACHE — override it and seed the hub
	# layout (refs/main + snapshots/<rev> symlinks into blobs/) directly
	# inside, then run offline.
	local -x LLAMA_INDEX_CACHE_DIR="${T}"/llama-index-cache
	local bge_repo=models--BAAI--bge-small-en
	slonko_test_seed_hf_repo "${LLAMA_INDEX_CACHE_DIR}" "${bge_repo}" 2275a7bdee235e9b4f01fa73aa60d3311983cfea <<-EOF
		bge-small-en-config.json|config.json
		bge-small-en-config_sentence_transformers.json|config_sentence_transformers.json
		bge-small-en-modules.json|modules.json
		bge-small-en-1_Pooling-config.json|1_Pooling/config.json
		bge-small-en-sentence_bert_config.json|sentence_bert_config.json
		bge-small-en-model.safetensors|model.safetensors
		bge-small-en-tokenizer.json|tokenizer.json
		bge-small-en-tokenizer_config.json|tokenizer_config.json
		bge-small-en-special_tokens_map.json|special_tokens_map.json
		bge-small-en-vocab.txt|vocab.txt
	EOF
	local -x HF_HUB_OFFLINE=1

	distutils-r1_src_test
}
