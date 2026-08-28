# Copyright 2019-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit go-module systemd

DESCRIPTION="TP-Link Tapo P110 and Tapo H200 Prometheus exporter written in Go"
HOMEPAGE="https://github.com/tess1o/go-tapo-exporter"
SRC_URI="https://github.com/tess1o/${PN}/archive/refs/tags/v${PV}.tar.gz"

EGO_SUM=(
	"github.com/beorn7/perks v1.0.1"
	"github.com/beorn7/perks v1.0.1/go.mod"
	"github.com/cespare/xxhash/v2 v2.3.0"
	"github.com/cespare/xxhash/v2 v2.3.0/go.mod"
	"github.com/google/go-cmp v0.6.0"
	"github.com/google/go-cmp v0.6.0/go.mod"
	"github.com/google/uuid v1.6.0"
	"github.com/google/uuid v1.6.0/go.mod"
	"github.com/klauspost/compress v1.17.9"
	"github.com/klauspost/compress v1.17.9/go.mod"
	"github.com/kylelemons/godebug v1.1.0"
	"github.com/kylelemons/godebug v1.1.0/go.mod"
	"github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822"
	"github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822/go.mod"
	"github.com/prometheus/client_golang v1.20.4"
	"github.com/prometheus/client_golang v1.20.4/go.mod"
	"github.com/prometheus/client_model v0.6.1"
	"github.com/prometheus/client_model v0.6.1/go.mod"
	"github.com/prometheus/common v0.55.0"
	"github.com/prometheus/common v0.55.0/go.mod"
	"github.com/prometheus/procfs v0.15.1"
	"github.com/prometheus/procfs v0.15.1/go.mod"
	"github.com/tess1o/tapo-go v0.2.0"
	"github.com/tess1o/tapo-go v0.2.0/go.mod"
	"golang.org/x/sys v0.22.0"
	"golang.org/x/sys v0.22.0/go.mod"
	"google.golang.org/protobuf v1.34.2"
	"google.golang.org/protobuf v1.34.2/go.mod"
)
go-module_set_globals
SRC_URI+="${EGO_SUM_SRC_URI}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	acct-group/go-tapo-exporter
	acct-user/go-tapo-exporter
"
BDEPEND=">=dev-lang/go-1.23.1"
RDEPEND="${DEPEND}"

src_compile() {
	ego build
}

src_install() {
	dobin ${PN}
	dodoc *.md
	insinto /etc/go-tapo-exporter
	doins docker-compose/config.json
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	fperms 0600 /etc/conf.d/"${PN}"
	systemd_dounit "${FILESDIR}/${PN}.service"
}
