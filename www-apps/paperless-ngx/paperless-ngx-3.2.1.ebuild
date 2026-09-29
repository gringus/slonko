# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit python-single-r1 systemd tmpfiles

DESCRIPTION="A community-supported supercharged document management system"
HOMEPAGE="https://github.com/paperless-ngx/paperless-ngx"
SRC_URI="https://github.com/paperless-ngx/paperless-ngx/releases/download/v${PV}/paperless-ngx-v${PV}.tar.xz"
S="${WORKDIR}/${PN}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="audit mysql postgres remote-redis +sqlite test zxing"
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
		dev-python/hiredis[${PYTHON_USEDEP}]
		dev-python/websockets[${PYTHON_USEDEP}]')
"
ALLAUTH_MFA_DEPEND="
	$(python_gen_cond_dep '
		>=dev-python/fido2-1.1.2[${PYTHON_USEDEP}]
		>=dev-python/qrcode-7.0.0[${PYTHON_USEDEP}]')
"
# Microsoft's Azure "Document Intelligence (REMOTE_OCR_ENGINE="azureai")
# - azure-ai-documentintelligence>=1.0.2
# PAPERLESS_AI_ENABLED=true
# - llama-index-core>=0.14.23
# - llama-index-embeddings-huggingface>=0.6.1
# - llama-index-embeddings-ollama>=0.9
# - llama-index-embeddings-openai-like>=0.2.2
# - llama-index-llms-ollama>=0.9.1
# - llama-index-llms-openai-like>=0.7.1
# - openai>=2.48
# - sentence-transformers>=5.6.1
# - sqlite-vec>=0.1.9
# - torch>=2.13.0 <2.15
RDEPEND="
	${ACCT_DEPEND}
	${ALLAUTH_MFA_DEPEND}
	${EXTRA_DEPEND}
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		>=dev-python/babel-2.17[${PYTHON_USEDEP}]
		>=dev-python/bleach-6.4.0[${PYTHON_USEDEP}]
		>=dev-python/celery-5.6.2[${PYTHON_USEDEP}]
		>=dev-python/channels-4.2[${PYTHON_USEDEP}]
		>=dev-python/channels-redis-4.2[${PYTHON_USEDEP}]
		>=dev-python/concurrent-log-handler-0.9.25[${PYTHON_USEDEP}]
		>=dev-python/dateparser-1.2[${PYTHON_USEDEP}]
		>=dev-python/django-5.2.13[${PYTHON_USEDEP}]
		<dev-python/django-6.0[${PYTHON_USEDEP}]
		>=dev-python/django-allauth-65.16.0[${PYTHON_USEDEP}]
		>=dev-python/django-cachalot-2.9.0[${PYTHON_USEDEP}]
		>=dev-python/django-compression-middleware-0.5.0[${PYTHON_USEDEP}]
		>=dev-python/django-cors-headers-4.9.0[${PYTHON_USEDEP}]
		>=dev-python/django-extensions-4.1[${PYTHON_USEDEP}]
		>=dev-python/django-filter-25.1[${PYTHON_USEDEP}]
		>=dev-python/django-guardian-3.3.3[${PYTHON_USEDEP}]
		<dev-python/django-guardian-3.5.0[${PYTHON_USEDEP}]
		>=dev-python/django-multiselectfield-1.0.1[${PYTHON_USEDEP}]
		dev-python/django-redis[${PYTHON_USEDEP}]
		>=dev-python/django-rich-2.2.0[${PYTHON_USEDEP}]
		>=dev-python/django-soft-delete-1.0.23[${PYTHON_USEDEP}]
		<dev-python/django-soft-delete-1.1[${PYTHON_USEDEP}]
		>=dev-python/django-treenode-0.24[${PYTHON_USEDEP}]
		>=dev-python/djangorestframework-3.16.0[${PYTHON_USEDEP}]
		>=dev-python/djangorestframework-guardian-0.4.0[${PYTHON_USEDEP}]
		>=dev-python/drf-spectacular-0.30[${PYTHON_USEDEP}]
		>=dev-python/drf-spectacular-sidecar-2026.7.1[${PYTHON_USEDEP}]
		<dev-python/drf-spectacular-sidecar-2026.10[${PYTHON_USEDEP}]
		>=dev-python/drf-writable-nested-0.7.1[${PYTHON_USEDEP}]
		>=dev-python/filelock-3.32.0[${PYTHON_USEDEP}]
		>=dev-python/gotenberg-client-1.0[${PYTHON_USEDEP}]
		>=dev-python/httpx-oauth-0.17[${PYTHON_USEDEP}]
		dev-python/humanize[${PYTHON_USEDEP}]
		>=dev-python/ijson-3.5.1[${PYTHON_USEDEP}]
		>=dev-python/imap-tools-1.14[${PYTHON_USEDEP}]
		<dev-python/imap-tools-1.16[${PYTHON_USEDEP}]
		>=dev-python/jinja2-3.1.6[${PYTHON_USEDEP}]
		>=dev-python/langdetect-1.0.9[${PYTHON_USEDEP}]
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
		>=dev-python/tantivy-0.26.0[${PYTHON_USEDEP}]
		>=dev-python/tika-client-1.0[${PYTHON_USEDEP}]
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
	media-gfx/imagemagick[xml]
	media-gfx/optipng
	media-libs/jbig2enc
	audit? ( $(python_gen_cond_dep '
		>=dev-python/django-auditlog-3.4.1[${PYTHON_USEDEP}]') )
	mysql? ( >=dev-python/mysqlclient-2.2.7 )
	postgres? ( $(python_gen_cond_dep '
		>=dev-python/psycopg-3.3.4[native-extensions,${PYTHON_USEDEP}]') )
	!remote-redis? ( dev-db/redis )
"
DEPEND="${RDEPEND}"
# Upstream testing dependency-group (pyproject.toml); live tests needing
# Gotenberg/Tika/GreenMail/nginx self-skip without PAPERLESS_CI_TEST set.
BDEPEND="test? (
	app-text/tessdata_fast[l10n_en(+)]
	$(python_gen_cond_dep '
		>=dev-python/django-auditlog-3.4.1[${PYTHON_USEDEP}]
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
)"

DOCS=( docker/rootfs/etc/ImageMagick-6/paperless-policy.xml )

EPYTEST_PLUGINS=(
	pytest-django
	pytest-env
	pytest-xdist
	pytest-mock
	pytest-httpx
	pytest-rerunfailures
)
EPYTEST_IGNORE=(
	# channels.testing pulls in daphne (unpackageable: dev-python/autobahn
	# missing in gentoo)
	src/paperless/tests/test_websockets.py
	# needs azure-ai-documentintelligence (Azure OCR, not packaged)
	src/paperless/tests/parsers/test_remote_parser.py
)
EPYTEST_DESELECT=(
	# webhook delivery to a real remote host (paperless-ngx.com)
	src/documents/tests/test_workflows.py::TestWebhookSend::test_send_webhook_data_or_json
	# needs sqlite-vec (AI stack, not packaged)
	src/documents/tests/test_api_app_config.py::TestApiAppConfig::test_update_llm_embedding_model_triggers_rebuild
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

	epytest
}

src_prepare() {
	default

	# AI tests need the llama-index stack, not packaged by this ebuild; their
	# conftest.py imports it at collection time, before --ignore applies.
	# Tests are stripped at install anyway.
	rm -rf src/paperless_ai/tests || die

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

	PAPERLESS_AUDIT_LOG_ENABLED=$(use audit && echo true || echo false)
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
