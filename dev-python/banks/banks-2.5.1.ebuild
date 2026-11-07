# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{11..14} )

inherit distutils-r1 pypi

DESCRIPTION="A prompt programming language"
HOMEPAGE="
	https://github.com/masci/banks
	https://pypi.org/project/banks/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/deprecated[${PYTHON_USEDEP}]
	>=dev-python/filetype-1.2.0[${PYTHON_USEDEP}]
	dev-python/griffe[${PYTHON_USEDEP}]
	dev-python/jinja2[${PYTHON_USEDEP}]
	dev-python/platformdirs[${PYTHON_USEDEP}]
	dev-python/pydantic[${PYTHON_USEDEP}]
"

# tests/test_completion.py needs the unpackaged litellm package
# (banks[all] extra).
EPYTEST_IGNORE=(
	tests/test_completion.py
)
EPYTEST_PLUGINS=( pytest-asyncio )
# test_prompt.py and test_utils.py import dev-python/regex directly although
# upstream only pulls it via litellm. Keep this assignment before
# distutils_enable_tests, which appends pytest + plugin deps to BDEPEND.
BDEPEND="
	test? (
		dev-db/redis
		dev-python/redis[${PYTHON_USEDEP}]
		dev-python/regex[${PYTHON_USEDEP}]
	)
"

distutils_enable_tests pytest

src_test() {
	local redis_pid="${T}"/redis.pid
	local redis_port=6379

	einfo "Spawning Redis"
	einfo "NOTE: Port ${redis_port} must be free"
	"${EPREFIX}"/usr/sbin/redis-server - <<-EOF || die "Unable to start redis server"
		daemonize yes
		pidfile ${redis_pid}
		port ${redis_port}
		bind 127.0.0.1 ::1
	EOF

	distutils-r1_src_test

	kill "$(<"${redis_pid}")" || die
}
