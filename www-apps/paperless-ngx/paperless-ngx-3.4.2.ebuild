# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit python-single-r1 slonko-test systemd tmpfiles

DESCRIPTION="A community-supported supercharged document management system"
HOMEPAGE="https://github.com/paperless-ngx/paperless-ngx"
SRC_URI="https://github.com/paperless-ngx/paperless-ngx/releases/download/v${PV}/paperless-ngx-v${PV}.tar.xz"
# Test-only distfiles: the AI tests tokenize via tiktoken's model registry,
# which fetches the encodings from openaipublic on first use (different
# code paths map to different encodings); pre-seeded in src_test.
SRC_URI+="
	test? (
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe
			-> tiktoken-gpt2-vocab.bpe
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json
			-> tiktoken-gpt2-encoder.json
		https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken
			-> tiktoken-r50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken
			-> tiktoken-p50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken
			-> tiktoken-cl100k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken
			-> tiktoken-o200k_base.tiktoken
	)
"
S="${WORKDIR}/${PN}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="audit compression huggingface mysql postgres ollama openai remote-redis +sqlite test"
REQUIRED_USE="
	${PYTHON_REQUIRED_USE}
	|| ( mysql postgres sqlite )
"

ACCT_DEPEND="
	acct-group/paperless
	acct-user/paperless
"
EXTRA_DEPEND="
	app-text/unpaper
	$(python_gen_cond_dep '
		dev-python/hiredis[${PYTHON_USEDEP}]')
"
ALLAUTH_MFA_DEPEND="
	$(python_gen_cond_dep '
		>=dev-python/fido2-1.1.2[${PYTHON_USEDEP}]
		>=dev-python/qrcode-7.0.0[${PYTHON_USEDEP}]')
"
# Shared AI core: llama-index vector store stack needed by every AI feature
# regardless of the configured backend. sqlite-vec is a C library package
# (dev-db) whose python binding is enabled via the python USE flag.
AI_CORE_DEPEND="
	$(python_gen_cond_dep '
		>=dev-python/llama-index-core-0.14.23[${PYTHON_USEDEP}]')
	dev-db/sqlite-vec[python]
"
AI_OPENAI_DEPEND="
	$(python_gen_cond_dep '
		>=dev-python/llama-index-llms-openai-like-0.7.1[${PYTHON_USEDEP}]
		>=dev-python/llama-index-embeddings-openai-like-0.2.2[${PYTHON_USEDEP}]
		>=dev-python/openai-2.48[${PYTHON_USEDEP}]
		')
"
AI_OLLAMA_DEPEND="
	$(python_gen_cond_dep '
		>=dev-python/llama-index-llms-ollama-0.9.1[${PYTHON_USEDEP}]
		>=dev-python/llama-index-embeddings-ollama-0.9[${PYTHON_USEDEP}]
		>=dev-python/ollama-0.5.3[${PYTHON_USEDEP}]
		')
"
AI_HUGGINGFACE_DEPEND="
	$(python_gen_cond_dep '
		>=dev-python/llama-index-embeddings-huggingface-0.6.1[${PYTHON_USEDEP}]
		>=dev-python/sentence-transformers-5.6.1[${PYTHON_USEDEP}]
		>=sci-ml/pytorch-2.13
		<sci-ml/pytorch-2.15
		')
"
AI_TEST_DEPEND="
	${AI_CORE_DEPEND}
	${AI_OPENAI_DEPEND}
	${AI_OLLAMA_DEPEND}
	${AI_HUGGINGFACE_DEPEND}
"
PATCHES=(
	# make django-compression-middleware optional for USE=-compression
	"${FILESDIR}/${PN}-optional-compression-middleware.patch"
	# stub channels.testing.live so test_websockets.py can run without daphne
	"${FILESDIR}/${PN}-channels-live-stub.patch"
)
# AI backends; PAPERLESS_AI_ENABLED is written from the USE flags below
# (the dep atoms live in AI_*_DEPEND above):
# - openai: remote LLM/embeddings via any OpenAI-compatible API
#   (sqlite-vec~=0.1.9: upstream pins ==0.1.9; ~ tolerates -rN revisions)
# - huggingface: local embeddings only, no extra service
# - ollama: local LLM/embeddings via an Ollama server
#   (ollama>=0.5.3 is the client; the server is sci-ml/ollama or remote)
# Not packaged:
# - Microsoft's Azure "Document Intelligence" (REMOTE_OCR_ENGINE="azureai")
# Version ceilings from llama-index pins, revisit on bump:
# - llama-index-llms-openai 0.8.x caps openai<3
# - llama-index-embeddings-openai-like 0.4.x caps llama-index-embeddings-openai<0.7
# tantivy-0.27 breaks whoosh-compat-0.3.0's emitter semantics (json/phrase
# query behavior changed); keep the search stack on 0.26 until whoosh-compat
# adapts
RDEPEND="
	${ACCT_DEPEND}
	${ALLAUTH_MFA_DEPEND}
	${EXTRA_DEPEND}
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		>=dev-python/babel-2.17[${PYTHON_USEDEP}]
		>=dev-python/celery-5.6.2[${PYTHON_USEDEP}]
		>=dev-python/channels-4.2[${PYTHON_USEDEP}]
		>=dev-python/channels-redis-4.2[${PYTHON_USEDEP}]
		>=dev-python/concurrent-log-handler-0.9.25[${PYTHON_USEDEP}]
		>=dev-python/dateparser-1.4[${PYTHON_USEDEP}]
		>=dev-python/django-5.2.18[${PYTHON_USEDEP}]
		<dev-python/django-6.0[${PYTHON_USEDEP}]
		>=dev-python/django-allauth-65.20.0[${PYTHON_USEDEP}]
		>=dev-python/django-cachalot-2.9.0[${PYTHON_USEDEP}]
		>=dev-python/django-cors-headers-4.9.0[${PYTHON_USEDEP}]
		>=dev-python/django-extensions-4.1[${PYTHON_USEDEP}]
		>=dev-python/django-filter-26.2[${PYTHON_USEDEP}]
		<dev-python/django-filter-27[${PYTHON_USEDEP}]
		>=dev-python/django-guardian-3.5.2[${PYTHON_USEDEP}]
		<dev-python/django-guardian-3.6.0[${PYTHON_USEDEP}]
		>=dev-python/django-multiselectfield-1.0.1[${PYTHON_USEDEP}]
		dev-python/django-redis[${PYTHON_USEDEP}]
		>=dev-python/django-rich-2.2.0[${PYTHON_USEDEP}]
		>=dev-python/django-soft-delete-1.0.23[${PYTHON_USEDEP}]
		<dev-python/django-soft-delete-1.1[${PYTHON_USEDEP}]
		>=dev-python/django-treenode-0.24[${PYTHON_USEDEP}]
		>=dev-python/djangorestframework-3.16.0[${PYTHON_USEDEP}]
		>=dev-python/drf-spectacular-0.30[${PYTHON_USEDEP}]
		>=dev-python/drf-spectacular-sidecar-2026.10.1[${PYTHON_USEDEP}]
		<dev-python/drf-spectacular-sidecar-2026.11[${PYTHON_USEDEP}]
		>=dev-python/drf-writable-nested-0.7.1[${PYTHON_USEDEP}]
		>=dev-python/filelock-3.32.0[${PYTHON_USEDEP}]
		<dev-python/filelock-4.3[${PYTHON_USEDEP}]
		>=dev-python/gotenberg-client-1.0[${PYTHON_USEDEP}]
		>=dev-python/httpx-oauth-0.17[${PYTHON_USEDEP}]
		dev-python/humanize[${PYTHON_USEDEP}]
		>=dev-python/ijson-3.5.1[${PYTHON_USEDEP}]
		>=dev-python/imap-tools-1.14[${PYTHON_USEDEP}]
		<dev-python/imap-tools-1.16[${PYTHON_USEDEP}]
		>=dev-python/jinja2-3.1.6[${PYTHON_USEDEP}]
		>=dev-python/langdetect-1.0.9[${PYTHON_USEDEP}]
		>=dev-python/nltk-data-20260801
		>=dev-python/pathvalidate-3.3.1[${PYTHON_USEDEP}]
		>=dev-python/pdf2image-1.17.0[${PYTHON_USEDEP}]
		>=dev-python/python-dateutil-2.9.0[${PYTHON_USEDEP}]
		>=dev-python/python-dotenv-1.2.1[${PYTHON_USEDEP}]
		>=dev-python/python-gnupg-0.5.4[${PYTHON_USEDEP}]
		>=dev-python/python-ipware-3.0.0[${PYTHON_USEDEP}]
		>=dev-python/python-magic-0.4.27[${PYTHON_USEDEP}]
		>=dev-python/rapidfuzz-3.14.5[${PYTHON_USEDEP}]
		>=dev-python/redis-6.4.0[${PYTHON_USEDEP}]
		<dev-python/redis-7.2.0[${PYTHON_USEDEP}]
		>=dev-python/regex-2026.7.19[${PYTHON_USEDEP}]
		>=dev-python/scikit-learn-1.9.0[${PYTHON_USEDEP}]
		>=dev-python/setproctitle-1.3.4[${PYTHON_USEDEP}]
		>=dev-python/tantivy-0.26.2[${PYTHON_USEDEP}]
		<dev-python/tantivy-0.27[${PYTHON_USEDEP}]
		>=dev-python/tika-client-1.0[${PYTHON_USEDEP}]
		>=dev-python/turbohtml-1.15.3[${PYTHON_USEDEP}]
		dev-python/uvloop[${PYTHON_USEDEP}]
		>=dev-python/watchfiles-1.2[${PYTHON_USEDEP}]
		>=dev-python/whitenoise-6.11[${PYTHON_USEDEP}]
		>=dev-python/whoosh-compat-0.3[${PYTHON_USEDEP}]
		>=media-libs/zxing-cpp-3.1.0[python,${PYTHON_USEDEP}]
		>=www-servers/granian-2.7[${PYTHON_USEDEP}]
		<www-servers/granian-2.9[${PYTHON_USEDEP}]')
	>=app-text/OCRmyPDF-17.12
	<app-text/OCRmyPDF-17.13
	app-text/poppler[utils]
	media-fonts/liberation-fonts
	media-libs/jbig2enc
	audit? ( $(python_gen_cond_dep '
		>=dev-python/django-auditlog-3.4.1[${PYTHON_USEDEP}]') )
	compression? ( $(python_gen_cond_dep '
		>=dev-python/django-compression-middleware-0.5.0[${PYTHON_USEDEP}]') )
	mysql? ( >=dev-python/mysqlclient-2.2.7 )
	postgres? ( $(python_gen_cond_dep '
		>=dev-python/psycopg-3.3.4[native-extensions,${PYTHON_USEDEP}]') )
	openai? (
		${AI_CORE_DEPEND}
		${AI_OPENAI_DEPEND}
	)
	ollama? (
		${AI_CORE_DEPEND}
		${AI_OLLAMA_DEPEND}
	)
	huggingface? (
		${AI_CORE_DEPEND}
		${AI_HUGGINGFACE_DEPEND}
	)
	!remote-redis? ( dev-db/redis )
"
DEPEND="${RDEPEND}"
# The AI test suite runs unconditionally with USE=test (no real LLM needed —
# all backends are mock-patched), testing everything the ebuild supports:
# all three backends incl. the torch chain.
BDEPEND="test? (
	app-text/tessdata_fast[l10n_en(+)]
	$(python_gen_cond_dep '
		dev-python/anyio[${PYTHON_USEDEP}]
		>=dev-python/django-auditlog-3.4.1[${PYTHON_USEDEP}]
		>=dev-python/django-compression-middleware-0.5.0[${PYTHON_USEDEP}]
		>=dev-python/factory-boy-3.3.1[${PYTHON_USEDEP}]
		>=dev-python/faker-40.36[${PYTHON_USEDEP}]
		dev-python/imagehash[${PYTHON_USEDEP}]
		>=dev-python/pytest-9.1.1[${PYTHON_USEDEP}]
		>=dev-python/pytest-django-4.12[${PYTHON_USEDEP}]
		<dev-python/pytest-django-4.15[${PYTHON_USEDEP}]
		>=dev-python/pytest-env-1.7[${PYTHON_USEDEP}]
		dev-python/pytest-httpx[${PYTHON_USEDEP}]
		>=dev-python/pytest-mock-3.15.1[${PYTHON_USEDEP}]
		>=dev-python/pytest-rerunfailures-16.4[${PYTHON_USEDEP}]
		>=dev-python/pytest-xdist-3.8[${PYTHON_USEDEP}]
		>=dev-python/time-machine-2.13[${PYTHON_USEDEP}]
	')
	${AI_TEST_DEPEND}
)"

EPYTEST_PLUGINS=(
	anyio
	pytest-django
	pytest-env
	pytest-xdist
	pytest-mock
	pytest-httpx
	pytest-rerunfailures
)
EPYTEST_IGNORE=(
	# needs azure-ai-documentintelligence (Azure OCR, not packaged)
	src/paperless/tests/parsers/test_remote_parser.py
)
EPYTEST_DESELECT=(
	# webhook delivery to a real remote host (paperless-ngx.com)
	src/documents/tests/test_workflows.py::TestWebhookSend::test_send_webhook_data_or_json
	# needs pillow HEIF support (ocrmypdf[heic] extra, not packaged)
	src/paperless/tests/parsers/test_tesseract_parser.py::TestParserFileTypes::test_heic
)

# Upstream pytest config (pyproject.toml [tool.pytest]) applies: pythonpath=src,
# DJANGO_SETTINGS_MODULE, pytest-env vars (locmem cache / in-memory channels,
# so no redis needed). Tests needing Gotenberg/Tika/GreenMail/nginx skip
# themselves because PAPERLESS_CI_TEST is intentionally not set.
src_test() {
	# Stop at the in-tree paperless.conf instead of a stale /etc/paperless.conf
	# left by an earlier merge (root:paperless 0640 is unreadable by the build
	# user and python-dotenv aborts on EACCES).
	local -x PAPERLESS_CONFIGURATION_PATH="${S}/paperless.conf"
	# The conf points data/media/consume at /var/lib/paperless (root-owned);
	# load_dotenv() does not override pre-set env vars, so redirect them to a
	# writable location like upstream CI (which runs on defaults).
	local -x PAPERLESS_DATA_DIR="${T}/data"
	local -x PAPERLESS_MEDIA_ROOT="${T}/media"
	local -x PAPERLESS_CONSUMPTION_DIR="${T}/consume"
	local -x PAPERLESS_CONVERT_TMPDIR="${T}/convert-tmp"
	# Tests exercise audit history regardless of the runtime audit USE flag;
	# django-auditlog is provided by TEST_DEPEND.
	local -x PAPERLESS_AUDIT_LOG_ENABLED=true
	# test_compression_middleware.py imports StreamAwareCompressionMiddleware
	# directly; the optional-compression patch only defines it when compression
	# is enabled (like upstream CI, which runs on defaults). The conf's
	# use-flag value would leave the class undefined with USE=-compression.
	local -x PAPERLESS_ENABLE_COMPRESSION=true
	# The generated paperless.conf derives PAPERLESS_AI_ENABLED from the USE
	# flags; tests run against upstream defaults (AI off) — the AI tests set
	# their own settings via override_settings.
	local -x PAPERLESS_AI_ENABLED=false
	# Seed the tiktoken encodings the AI tests tokenize with (see SRC_URI).
	slonko_test_seed_tiktoken_cache "${T}"/tiktoken-cache <<-EOF
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/vocab.bpe|tiktoken-gpt2-vocab.bpe
		https://openaipublic.blob.core.windows.net/gpt-2/encodings/main/encoder.json|tiktoken-gpt2-encoder.json
		https://openaipublic.blob.core.windows.net/encodings/r50k_base.tiktoken|tiktoken-r50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/p50k_base.tiktoken|tiktoken-p50k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/cl100k_base.tiktoken|tiktoken-cl100k_base.tiktoken
		https://openaipublic.blob.core.windows.net/encodings/o200k_base.tiktoken|tiktoken-o200k_base.tiktoken
	EOF
	epytest
}

src_prepare() {
	default

	# drop coverage addopts: pytest-cov is not installed
	sed -i -e '/--cov/d' pyproject.toml || die

	sed \
		-e "s|#PAPERLESS_CONSUMPTION_DIR=../consume|PAPERLESS_CONSUMPTION_DIR=/var/lib/paperless/consume|" \
		-e "s|#PAPERLESS_DATA_DIR=../data|PAPERLESS_DATA_DIR=/var/lib/paperless/data|" \
		-e "s|#PAPERLESS_MEDIA_ROOT=../media|PAPERLESS_MEDIA_ROOT=/var/lib/paperless/media|" \
		-e "s|#PAPERLESS_STATICDIR=../static|PAPERLESS_STATICDIR=/usr/share/paperless/static|" \
		-e "s|#PAPERLESS_CONVERT_TMPDIR=/var/tmp/paperless|PAPERLESS_CONVERT_TMPDIR=/var/lib/paperless/tmp|" \
		-i "paperless.conf" || die "Cannot update paperless.conf"

	cat >> "paperless.conf" <<- EOF

	# Custom
	# PAPERLESS_BIND_ADDR=::
	# PAPERLESS_PORT=8000
	# PAPERLESS_WEBSERVER_WORKERS=1

	PAPERLESS_ENABLE_COMPRESSION=$(use compression && echo true || echo false)
	PAPERLESS_AUDIT_LOG_ENABLED=$(use audit && echo true || echo false)
	PAPERLESS_AI_ENABLED=$( { use openai || use huggingface || use ollama; } && echo true || echo false)
	# PAPERLESS_AI_LLM_EMBEDDING_BACKEND=openai-like
	# PAPERLESS_AI_LLM_EMBEDDING_ENDPOINT=http://localhost:8000/v1
	# PAPERLESS_AI_LLM_EMBEDDING_MODEL=...
	# PAPERLESS_AI_LLM_BACKEND=openai-like
	# PAPERLESS_AI_LLM_ENDPOINT=http://localhost:8000/v1
	# PAPERLESS_AI_LLM_MODEL=...
	# See https://github.com/paperless-ngx/paperless-ngx/discussions/9920
	OMP_NUM_THREADS=1
	EOF
}

src_install() {
	einstalldocs

	# Install service files
	systemd_newunit "${FILESDIR}"/paperless-webserver.service paperless-webserver.service
	systemd_newunit "${FILESDIR}"/paperless-scheduler.service paperless-scheduler.service
	systemd_newunit "${FILESDIR}"/paperless-consumer.service paperless-consumer.service
	systemd_newunit "${FILESDIR}"/paperless-task-queue.service paperless-task-queue.service
	systemd_newunit "${FILESDIR}"/paperless.target paperless.target

	# OpenRC manages the same four daemons in a single script (like paperless.target)
	newinitd "${FILESDIR}"/paperless.initd paperless

	if use remote-redis; then
		sed -e '/redis\.service/d' -i *.service "${D}$(systemd_get_systemunitdir)"/*.service
		sed -e '/need redis/d' -i "${ED}"/etc/init.d/paperless
	fi

	# Install paperless files
	insinto /usr/share/paperless
	doins -r docs src static
	rm -rf "${ED}"/usr/share/paperless/src/*/tests || die

	insinto /etc
	doins paperless.conf
	fowners root:paperless /etc/paperless.conf
	fperms 640 /etc/paperless.conf

	newtmpfiles "${FILESDIR}"/paperless.tmpfiles paperless.conf

	# Set directories
	for dir in consume data media tmp; do
		keepdir /var/lib/paperless/${dir}
		fowners paperless:paperless /var/lib/paperless/${dir}
		case "${dir}" in
		data) fperms 700 /var/lib/paperless/${dir} ;;
		*)    fperms 750 /var/lib/paperless/${dir} ;;
		esac
	done

	# AI resource caches: tiktoken encodings
	keepdir /var/lib/paperless/data/tiktoken_cache
	fowners paperless:paperless /var/lib/paperless/data/tiktoken_cache
	fperms 700 /var/lib/paperless/data/tiktoken_cache

	# Main executable
	fperms 755 "/usr/share/paperless/src/manage.py"
	dosym -r "/usr/share/paperless/src/manage.py" "/usr/bin/paperless-manage"
}

pkg_postinst() {
	tmpfiles_process paperless.conf
	elog "To complete the installation of paperless, edit /etc/paperless.conf file and"
	elog "* Create the database"
	elog "  sudo -u paperless paperless-manage migrate"
	elog "* Create a super user account with"
	elog "  sudo -u paperless paperless-manage createsuperuser"
	elog " "
	elog "After each update of paperless, you should run migration with"
	elog "  sudo -u paperless paperless-manage migrate"
	elog " "
	elog "Paperless services can be (re)started together with"
	elog "  sudo systemctl (re)start paperless.target"
	elog "on OpenRC (add with rc-update add paperless default)"
	elog "  sudo rc-service paperless restart"
	elog " "
	elog "If you are upgrading from <paperless-ngx-3.0 check below docs"
	elog "https://docs.paperless-ngx.com/migration-v3/"
}
