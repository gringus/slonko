# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
DISTUTILS_SINGLE_IMPL=1
PYTHON_COMPAT=( python3_{13..15} )

EGIT_REPO_URI="https://github.com/searxng/searxng.git"

inherit distutils-r1 git-r3 systemd

DESCRIPTION="Free internet metasearch engine"
HOMEPAGE="https://docs.searxng.org/"

LICENSE="AGPL-3+"
SLOT="0"
IUSE="granian"

RDEPEND="
	acct-group/searxng
	acct-user/searxng
	granian? ( $(python_gen_cond_dep 'www-servers/granian[${PYTHON_USEDEP}]') )

	$(python_gen_cond_dep '
		dev-python/certifi[${PYTHON_USEDEP}]
		dev-python/babel[${PYTHON_USEDEP}]
		dev-python/flask-babel[${PYTHON_USEDEP}]
		dev-python/flask[${PYTHON_USEDEP}]
		dev-python/jinja2[${PYTHON_USEDEP}]
		dev-python/lxml[${PYTHON_USEDEP}]
		dev-python/pygments[${PYTHON_USEDEP}]
		dev-python/python-dateutil[${PYTHON_USEDEP}]
		dev-python/pyyaml[${PYTHON_USEDEP}]
		dev-python/curl-cffi[${PYTHON_USEDEP}]
		dev-python/valkey[${PYTHON_USEDEP}]
		dev-python/markdown-it-py[${PYTHON_USEDEP}]
		dev-python/msgspec[${PYTHON_USEDEP}]
		dev-python/typer[${PYTHON_USEDEP}]
		dev-python/isodate[${PYTHON_USEDEP}]
		dev-python/whitenoise[${PYTHON_USEDEP}]
		dev-python/typing-extensions[${PYTHON_USEDEP}]
	')
"
BDEPEND="
	test? (
		$(python_gen_cond_dep '
			dev-python/aiounittest[${PYTHON_USEDEP}]
			dev-python/mock[${PYTHON_USEDEP}]
			dev-python/parameterized[${PYTHON_USEDEP}]
		')
	)
"

EPYTEST_DESELECT=(
	# Requires pytest-playwright
	"tests/robot/test_webapp.py"
)

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

src_prepare() {
	default

	# Fix for newer lxml
	sed -i -e \
		"s/self.assertEqual(context.exception.message, 'Unregistered function')/self.assertIn('Unregistered function', str(context.exception))/" \
		tests/unit/test_utils.py || die
}

src_compile() {
	# importing searx at build time runs init_settings(), which would read the
	# live /etc/searxng/settings.yml and fail when portage can't; use a stub
	export SEARXNG_SETTINGS_PATH="${T}/settings.yml"
	echo "use_default_settings: true" > "${SEARXNG_SETTINGS_PATH}" || die
	distutils-r1_src_compile
}

src_test() {
	export SEARXNG_SETTINGS_PATH="${T}/settings.yml"
	[[ -e ${SEARXNG_SETTINGS_PATH} ]] || echo "use_default_settings: true" > "${SEARXNG_SETTINGS_PATH}" || die
	distutils-r1_src_test
}

src_install() {
	distutils-r1_src_install

	insinto /etc/searxng
	newins "${FILESDIR}/settings.yml" settings.yml
	fowners root:searxng /etc/searxng/settings.yml
	fperms 0640 /etc/searxng/settings.yml

	if use granian; then
		newconfd "${FILESDIR}/searxng.confd" searxng
		systemd_newunit "${FILESDIR}/searxng-granian.service" searxng.service
	else
		systemd_dounit "${FILESDIR}/searxng.service"
	fi
}

pkg_postinst() {
	# searxng refuses to start with the shipped placeholder secret key
	local f="/etc/searxng/settings.yml"
	if grep -q '^  secret_key: ultrasecretkey' "${f}" 2>/dev/null; then
		local secret="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)"
		sed -i "s|^  secret_key: ultrasecretkey.*|  secret_key: \"${secret}\"|" "${f}" || die
		chown root:searxng "${f}"  # sed -i creates a fresh file
		chmod 0640 "${f}"
	fi
}
