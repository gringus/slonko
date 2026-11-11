# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1

DESCRIPTION="Easily serialize dataclasses to and from JSON"
HOMEPAGE="
	https://github.com/lidatong/dataclasses-json
	https://pypi.org/project/dataclasses-json/
"
SRC_URI="https://github.com/lidatong/dataclasses-json/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	<dev-python/marshmallow-4[${PYTHON_USEDEP}]
	>=dev-python/marshmallow-3.18.0[${PYTHON_USEDEP}]
	>=dev-python/typing-inspect-0.4.0[${PYTHON_USEDEP}]
"

# tests/test_annotations.py runs the mypy plugin via mypy itself
BDEPEND="
	test? (
		dev-python/hypothesis[${PYTHON_USEDEP}]
		dev-python/mypy[${PYTHON_USEDEP}]
		dev-python/simplejson[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest

src_prepare() {
	# Replace poetry-dynamic-versioning with plain poetry-core; the pyproject
	# ships a static 0.0.0 placeholder we substitute with ${PV}.
	sed -e "s/0\.0\.0/${PV}/g" \
		-e 's/, "poetry-dynamic-versioning"//' \
		-e 's/poetry_dynamic_versioning.backend/poetry.core.masonry.api/' \
		-i pyproject.toml || die
	# _get_catch_all_field() is also called with instances (handle_dump,
	# create_init); typing.get_type_hints() on an instance is rejected by
	# Python 3.14's annotationlib (worked via attribute fallback before).
	sed -i \
		-e '/^    def _get_catch_all_field(cls) -> Field:/a\        cls = cls if isinstance(cls, type) else type(cls)' \
		dataclasses_json/undefined.py || die
	default
}
