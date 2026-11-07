# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=pdm-backend
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="Signatures for entire Python programs. Extract the structure, the frame traceback and 16 other formats"
HOMEPAGE="
	https://mkdocstrings.github.io/griffe/
	https://github.com/mkdocstrings/griffe
	https://pypi.org/project/griffe/
"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND=">=dev-python/colorama-0.4[${PYTHON_USEDEP}]"

BDEPEND="
	test? (
		dev-vcs/git
		dev-python/jsonschema[${PYTHON_USEDEP}]
	)
"

# tests/test_api.py builds the mkdocstrings inventory and needs the
# mkdocstrings package (mkdocs ecosystem, not packaged); everything else is
# self-contained (jsonschema + a git binary for test_git.py).
EPYTEST_IGNORE=(
	tests/test_api.py
)
distutils_enable_tests pytest
