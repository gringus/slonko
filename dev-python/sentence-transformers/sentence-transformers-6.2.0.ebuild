# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Embeddings, Retrieval, and Reranking"
HOMEPAGE="
	https://github.com/huggingface/sentence-transformers
	https://pypi.org/project/sentence-transformers/
"
SRC_URI="
	https://github.com/huggingface/sentence-transformers/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz
	test? (
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/config.json -> stsb-bert-tiny-config.json
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/modules.json -> stsb-bert-tiny-modules.json
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/1_Pooling/config.json -> stsb-bert-tiny-1_Pooling-config.json
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/sentence_bert_config.json -> stsb-bert-tiny-sentence_bert_config.json
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/model.safetensors -> stsb-bert-tiny-model.safetensors
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/tokenizer.json -> stsb-bert-tiny-tokenizer.json
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/tokenizer_config.json -> stsb-bert-tiny-tokenizer_config.json
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/special_tokens_map.json -> stsb-bert-tiny-special_tokens_map.json
		https://huggingface.co/sentence-transformers-testing/stsb-bert-tiny-safetensors/resolve/f3cb857cba53019a20df283396bcca179cf051a4/vocab.txt -> stsb-bert-tiny-vocab.txt
		https://huggingface.co/google-bert/bert-base-uncased/resolve/86b5e0934494bd15c9632b12f734a8a67f723594/tokenizer.json -> bert-base-uncased-tokenizer.json
		https://huggingface.co/google-bert/bert-base-uncased/resolve/86b5e0934494bd15c9632b12f734a8a67f723594/tokenizer_config.json -> bert-base-uncased-tokenizer_config.json
		https://huggingface.co/google-bert/bert-base-uncased/resolve/86b5e0934494bd15c9632b12f734a8a67f723594/vocab.txt -> bert-base-uncased-vocab.txt
		https://huggingface.co/google-bert/bert-base-uncased/resolve/86b5e0934494bd15c9632b12f734a8a67f723594/config.json -> bert-base-uncased-config.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce-STv54/resolve/bac0cf4def13f328707f1c0cddd688a56b567bb6/config.json -> reranker-gooaq-config.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce-STv54/resolve/bac0cf4def13f328707f1c0cddd688a56b567bb6/modules.json -> reranker-gooaq-modules.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce-STv54/resolve/bac0cf4def13f328707f1c0cddd688a56b567bb6/sentence_bert_config.json -> reranker-gooaq-sentence_bert_config.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce-STv54/resolve/bac0cf4def13f328707f1c0cddd688a56b567bb6/model.safetensors -> reranker-gooaq-model.safetensors
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce-STv54/resolve/bac0cf4def13f328707f1c0cddd688a56b567bb6/tokenizer.json -> reranker-gooaq-tokenizer.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce-STv54/resolve/bac0cf4def13f328707f1c0cddd688a56b567bb6/tokenizer_config.json -> reranker-gooaq-tokenizer_config.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce-STv54/resolve/bac0cf4def13f328707f1c0cddd688a56b567bb6/special_tokens_map.json -> reranker-gooaq-special_tokens_map.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce-STv54/resolve/bac0cf4def13f328707f1c0cddd688a56b567bb6/vocab.txt -> reranker-gooaq-vocab.txt
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce/resolve/0d75677beaddce2ff048cbd96079c3e2ce0e984f/config.json -> reranker-bce-config.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce/resolve/0d75677beaddce2ff048cbd96079c3e2ce0e984f/model.safetensors -> reranker-bce-model.safetensors
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce/resolve/0d75677beaddce2ff048cbd96079c3e2ce0e984f/special_tokens_map.json -> reranker-bce-special_tokens_map.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce/resolve/0d75677beaddce2ff048cbd96079c3e2ce0e984f/tokenizer.json -> reranker-bce-tokenizer.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce/resolve/0d75677beaddce2ff048cbd96079c3e2ce0e984f/tokenizer_config.json -> reranker-bce-tokenizer_config.json
		https://huggingface.co/cross-encoder-testing/reranker-bert-tiny-gooaq-bce/resolve/0d75677beaddce2ff048cbd96079c3e2ce0e984f/vocab.txt -> reranker-bce-vocab.txt
	)
"

LICENSE="Apache-2.0"
# The pre-seeded model files are redistributable per their hub licenses.
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=sci-ml/huggingface_hub-1.3.0
	<sci-ml/huggingface_hub-3.0.0
	>=dev-python/numpy-1.24.0[${PYTHON_USEDEP}]
	>=dev-python/scikit-learn-1.1.0[${PYTHON_USEDEP}]
	>=dev-python/scipy-1.0.0[${PYTHON_USEDEP}]
	>=sci-ml/tokenizers-0.19
	>=sci-ml/transformers-5.0.0
	<sci-ml/transformers-6.0.0
	>=sci-ml/pytorch-2.2
	>=dev-python/tqdm-4.0[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.10.0[${PYTHON_USEDEP}]
"

# pytest-env provides the `env` ini option used by the upstream pytest config.
# EPYTEST_XDIST parallelizes the ~4k-test suite; the datasets-importing tests
# (tests/sentence_transformer/evaluation/test_reranking_evaluator.py and
# tests/base/modules/test_router.py) build datasets locally.
EPYTEST_PLUGINS=( pytest-env )
EPYTEST_XDIST=1
BDEPEND="
	test? (
		sci-ml/accelerate
		sci-ml/datasets
	)
"

# Hub-integration tests excluded from the offline run: they download models,
# datasets or need unpackaged extras (peft/faiss-cpu/usearch/fastcluster/
# mergekit/model2vec/optimum) or torch.distributed
# (sci-ml/pytorch[distributed]). Extend this list as new offenders surface.
EPYTEST_IGNORE=(
	tests/base/modules/test_transformer.py
	tests/base/modules/transformer
	tests/base/test_distributed_evaluation.py
	tests/base/test_gradcache_distributed.py
	tests/base/test_model.py
	tests/base/test_model_card.py
	tests/base/test_model_type_subclass.py
	tests/base/test_trainer.py
	tests/multi_vector_encoder/test_evaluators.py
	tests/multi_vector_encoder/test_model.py
	tests/multi_vector_encoder/test_model_card.py
	tests/multi_vector_encoder/test_multi_process.py
	tests/multi_vector_encoder/test_pretrained.py
	tests/multi_vector_encoder/test_trainer.py
	tests/sentence_transformer/evaluation/test_label_accuracy_evaluator.py
	tests/sentence_transformer/evaluation/test_nanobeir_evaluator.py
	tests/sentence_transformer/losses/test_matryoshka.py
	tests/sentence_transformer/losses/test_cmnrl.py
	tests/sentence_transformer/test_custom_models.py
	tests/sentence_transformer/test_image_embeddings.py
	tests/sentence_transformer/test_model.py
	tests/sentence_transformer/test_multi_process.py
	tests/sentence_transformer/test_pretrained.py
	tests/sentence_transformer/test_pretrained_stsb.py
	tests/sentence_transformer/test_trainer.py
	tests/sentence_transformer/test_train_stsb.py
	tests/cross_encoder/test_multi_process.py
	tests/cross_encoder/test_pretrained.py
	tests/cross_encoder/test_trainer.py
	tests/cross_encoder/test_train_stsb.py
	tests/sparse_encoder/evaluation/test_binary_classification_evaluator.py
	tests/sparse_encoder/evaluation/test_embedding_similarity_evaluator.py
	tests/sparse_encoder/evaluation/test_triplet_evaluator.py
	tests/sparse_encoder/losses/test_cached_splade.py
	tests/sparse_encoder/losses/test_merged_forward.py
	tests/sparse_encoder/losses/test_sparse_cosent.py
	tests/sparse_encoder/losses/test_sparse_distill_kl_div.py
	tests/sparse_encoder/modules/test_csr.py
	tests/sparse_encoder/modules/test_sparse_static_embedding.py
	tests/sparse_encoder/test_model.py
	tests/sparse_encoder/test_model_card.py
	tests/sparse_encoder/test_multi_process.py
	tests/sparse_encoder/test_pretrained.py
	tests/sparse_encoder/test_trainer.py
	tests/sparse_encoder/test_train_stsb.py
	tests/test_merging.py
	tests/util/test_dataset.py
	tests/util/test_file_io.py
	tests/util/test_hard_negatives.py
)
# Single tests excluded from otherwise-clean files:
# - mnr world-size tests need torch.distributed (sci-ml/pytorch[distributed]).
# - test_loading_model2vec needs the unpackaged model2vec package.
# - the short-sha revision param needs Hub access (the full-sha one passes).
# - test_pairwise_angle_sim_even_and_odd_sparse_embeddings loads
#   sparse-encoder-testing/splade-bert-tiny-nq from the HF Hub.
# - the Trainer tests need torch.distributed (sci-ml/pytorch[distributed]).
EPYTEST_DESELECT=(
	'tests/multi_vector_encoder/losses/test_misc.py::test_mnr_loss_does_not_scale_with_world_size[mnrl]'
	'tests/multi_vector_encoder/losses/test_misc.py::test_mnr_loss_does_not_scale_with_world_size[cached_mnrl]'
	'tests/sentence_transformer/modules/test_static_embedding.py::test_loading_model2vec'
	'tests/sentence_transformer/test_model_card_data.py::test_model_card_data[f3cb857-f3cb857]'
	'tests/util/test_similarity.py::test_pairwise_angle_sim_even_and_odd_sparse_embeddings'
	'tests/sentence_transformer/losses/test_softmax.py::test_trainer_accepts_probability_labels'
	'tests/base/modules/test_router.py::test_router_with_trainer'
	'tests/base/modules/test_router.py::test_router_with_trainer_without_router_mapping'
	# The next three need Hub access to specific revisions/models.
	'tests/cross_encoder/test_model.py::test_load_with_revision'
	'tests/cross_encoder/test_model.py::test_load_activation_fn_from_config[cross-encoder-testing/reranker-bert-tiny-gooaq-bce-tanh-v3]'
	'tests/cross_encoder/test_model.py::test_load_activation_fn_from_config[cross-encoder-testing/reranker-bert-tiny-gooaq-bce-tanh-v4]'
)
distutils_enable_tests pytest

python_test() {
	local hf_cache="${T}"/hf-cache
	_seed_hf_repo models--sentence-transformers-testing--stsb-bert-tiny-safetensors f3cb857cba53019a20df283396bcca179cf051a4 <<-EOF
		stsb-bert-tiny-config.json|config.json
		stsb-bert-tiny-modules.json|modules.json
		stsb-bert-tiny-1_Pooling-config.json|1_Pooling/config.json
		stsb-bert-tiny-sentence_bert_config.json|sentence_bert_config.json
		stsb-bert-tiny-model.safetensors|model.safetensors
		stsb-bert-tiny-tokenizer.json|tokenizer.json
		stsb-bert-tiny-tokenizer_config.json|tokenizer_config.json
		stsb-bert-tiny-special_tokens_map.json|special_tokens_map.json
		stsb-bert-tiny-vocab.txt|vocab.txt
	EOF
	# tokenizer files for the session-scoped _tokenizer fixture; the full
	# model is NOT needed.
	_seed_hf_repo models--google-bert--bert-base-uncased 86b5e0934494bd15c9632b12f734a8a67f723594 <<-EOF
		bert-base-uncased-tokenizer.json|tokenizer.json
		bert-base-uncased-tokenizer_config.json|tokenizer_config.json
		bert-base-uncased-vocab.txt|vocab.txt
		bert-base-uncased-config.json|config.json
	EOF
	_seed_hf_repo models--cross-encoder-testing--reranker-bert-tiny-gooaq-bce-STv54 bac0cf4def13f328707f1c0cddd688a56b567bb6 <<-EOF
		reranker-gooaq-config.json|config.json
		reranker-gooaq-modules.json|modules.json
		reranker-gooaq-sentence_bert_config.json|sentence_bert_config.json
		reranker-gooaq-model.safetensors|model.safetensors
		reranker-gooaq-tokenizer.json|tokenizer.json
		reranker-gooaq-tokenizer_config.json|tokenizer_config.json
		reranker-gooaq-special_tokens_map.json|special_tokens_map.json
		reranker-gooaq-vocab.txt|vocab.txt
	EOF
	_seed_hf_repo models--cross-encoder-testing--reranker-bert-tiny-gooaq-bce 0d75677beaddce2ff048cbd96079c3e2ce0e984f <<-EOF
		reranker-bce-config.json|config.json
		reranker-bce-model.safetensors|model.safetensors
		reranker-bce-special_tokens_map.json|special_tokens_map.json
		reranker-bce-tokenizer.json|tokenizer.json
		reranker-bce-tokenizer_config.json|tokenizer_config.json
		reranker-bce-vocab.txt|vocab.txt
	EOF
	local -x HF_HUB_CACHE="${hf_cache}/hub"
	local -x HF_HUB_OFFLINE=1

	epytest
}

_seed_hf_repo() {
	local repo=$1 rev=$2
	local repo_dir="${T}/hf-cache/hub/${repo}"
	mkdir -p "${repo_dir}/refs" "${repo_dir}/blobs" "${repo_dir}/snapshots/${rev}" || die
	printf '%s' "${rev}" > "${repo_dir}/refs/main" || die
	local entry distfile path destdir ups slashes
	while read -r entry; do
		[[ -z ${entry} ]] && continue
		distfile=${entry%%|*}
		path=${entry#*|}
		cp "${DISTDIR}/${distfile}" "${repo_dir}/blobs/${distfile}" || die
		destdir="${repo_dir}/snapshots/${rev}"/$(dirname "${path}")
		mkdir -p "${destdir}" || die
		# The symlink lives one dir deeper per path component: blobs/ is
		# reached via ../../ from snapshot root, ../../../ from a subfolder.
		slashes="${path//[!\/]/}"
		ups="../../"
		for ((i = 0; i < ${#slashes}; i++)); do ups="${ups}/.."; done
		ln -s "${ups}/blobs/${distfile}" "${repo_dir}/snapshots/${rev}/${path}" || die
	done
}
