# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{9..13} )

inherit distutils-r1 optfeature

DESCRIPTION="Django 3rd party (social) account authentication"
HOMEPAGE="
	https://allauth.org/
	https://github.com/pennersr/django-allauth/
	https://pypi.org/project/django-allauth/
"
SRC_URI="https://github.com/pennersr/${PN}/archive/${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-python/asgiref-3.8.1[${PYTHON_USEDEP}]
	>=dev-python/django-4.2.16[${PYTHON_USEDEP}]
	>=dev-python/pyjwt-2.0[${PYTHON_USEDEP}]
	<dev-python/pyjwt-3[${PYTHON_USEDEP}]
	>=dev-python/oauthlib-3.3.0[${PYTHON_USEDEP}]
	<dev-python/oauthlib-4[${PYTHON_USEDEP}]
	>=dev-python/requests-2.0.0[${PYTHON_USEDEP}]
	<dev-python/requests-3[${PYTHON_USEDEP}]
"
# cryptography via pyjwt[crypto]
RDEPEND+="
	dev-python/cryptography[${PYTHON_USEDEP}]
"
BDEPEND="
	dev-python/setuptools-scm[${PYTHON_USEDEP}]
	test? (
		>=dev-python/django-ninja-1.3.0[${PYTHON_USEDEP}]
		<dev-python/django-ninja-2[${PYTHON_USEDEP}]
		>=dev-python/djangorestframework-3.15.2[${PYTHON_USEDEP}]
		<dev-python/djangorestframework-4[${PYTHON_USEDEP}]
		>=dev-python/fido2-1.1.2[${PYTHON_USEDEP}]
		<dev-python/fido2-3[${PYTHON_USEDEP}]
		dev-python/psycopg[${PYTHON_USEDEP}]
		>=dev-python/pytest-asyncio-0.23.8[${PYTHON_USEDEP}]
		>=dev-python/pytest-django-4.5.2[${PYTHON_USEDEP}]
		>=dev-python/python3-openid-3.0.8[${PYTHON_USEDEP}]
		<dev-python/python3-openid-4[${PYTHON_USEDEP}]
		>=dev-python/python3-saml-1.15.0[${PYTHON_USEDEP}]
		<dev-python/python3-saml-2.0.0[${PYTHON_USEDEP}]
		>=dev-python/pyyaml-6[${PYTHON_USEDEP}]
		<dev-python/pyyaml-7[${PYTHON_USEDEP}]
		>=dev-python/qrcode-7.0.0[${PYTHON_USEDEP}]
		<dev-python/qrcode-9[${PYTHON_USEDEP}]
	)
"

export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}

DOCS=( README.rst AUTHORS ChangeLog.rst )

distutils_enable_tests pytest
distutils_enable_sphinx docs \
	dev-python/sphinx-rtd-theme

pkg_postinst() {
	optfeature "MFA (Multi-factor authentication)" dev-python/qrcode dev-python/fido2
	optfeature "OpenID or Steam" dev-python/python3-openid
	optfeature "SAML authentication" dev-python/python3-saml
}
