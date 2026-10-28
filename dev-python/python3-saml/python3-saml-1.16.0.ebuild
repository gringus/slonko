# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="OneLogin's SAML Python Toolkit"
HOMEPAGE="
	https://github.com/SAML-Toolkits/python3-saml/
	https://pypi.org/project/python3-saml/
"
SRC_URI="
	https://github.com/SAML-Toolkits/python3-saml/archive/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/isodate-0.6.1[${PYTHON_USEDEP}]
	>=dev-python/lxml-4.9.0[${PYTHON_USEDEP}]
	>=dev-python/xmlsec-1.3.9[${PYTHON_USEDEP}]
"
# next release >1.16.0 should be able to drop freezegun:
# https://github.com/SAML-Toolkits/python3-saml/commit/6c1fbd84ed498841b252ba7eb3a7d81a9ea77d15
BDEPEND="
	test? (
		dev-python/freezegun[${PYTHON_USEDEP}]
		dev-python/pytest[${PYTHON_USEDEP}]
	)
"

EPYTEST_PLUGINS=( )
distutils_enable_tests pytest

python_test() {
	local EPYTEST_DESELECT=(
		# Internet
		tests/src/OneLogin/saml2_tests/idp_metadata_parser_test.py::OneLogin_Saml2_IdPMetadataParser_Test::testGetMetadataWithHeaders
		tests/src/OneLogin/saml2_tests/idp_metadata_parser_test.py::OneLogin_Saml2_IdPMetadataParser_Test::testParseRemoteWithHeaders

		# Time-bombed fixtures: hardcoded 2024-era NotBefore/NotOnOrAfter and
		# SessionNotOnOrAfter dates have aged past "now", so the expected
		# expired/not-yet-valid errors no longer fire. The mechanism itself
		# works (the non-aged variants of the same tests pass).
		tests/src/OneLogin/saml2_tests/response_test.py::OneLogin_Saml2_Response_Test::testIsInValidEncIssues_2
		tests/src/OneLogin/saml2_tests/response_test.py::OneLogin_Saml2_Response_Test::testValidateTimestamps

		# Fragile positional navigation (firstChild.nextSibling.nextSibling)
		# that lands on a whitespace Text node with current lxml/xmlsec; the
		# signed output itself is fine (<ds:SignatureValue> asserted earlier
		# in the same test passes).
		tests/src/OneLogin/saml2_tests/utils_test.py::OneLogin_Saml2_Utils_Test::testAddSign
	)

	# The tests are horribly fragile to paths.
	local -x PYTHONPATH=src
	epytest -o 'python_files=*_test.py'
}
