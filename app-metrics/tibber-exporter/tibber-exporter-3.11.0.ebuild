# Copyright 2019-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
inherit go-module systemd

DESCRIPTION="Monitor your power usage and costs with Prometheus and Grafana"
HOMEPAGE="https://github.com/terjesannum/tibber-exporter"
SRC_URI="https://github.com/terjesannum/tibber-exporter/archive/${P}.tar.gz"

EGO_SUM=(
	"github.com/beorn7/perks v1.0.1"
	"github.com/beorn7/perks v1.0.1/go.mod"
	"github.com/cespare/xxhash/v2 v2.3.0"
	"github.com/cespare/xxhash/v2 v2.3.0/go.mod"
	"github.com/coder/websocket v1.8.15"
	"github.com/coder/websocket v1.8.15/go.mod"
	"github.com/google/go-cmp v0.7.0"
	"github.com/google/go-cmp v0.7.0/go.mod"
	"github.com/google/uuid v1.6.0"
	"github.com/google/uuid v1.6.0/go.mod"
	"github.com/hasura/go-graphql-client v0.16.0"
	"github.com/hasura/go-graphql-client v0.16.0/go.mod"
	"github.com/klauspost/compress v1.19.1"
	"github.com/klauspost/compress v1.19.1/go.mod"
	"github.com/kylelemons/godebug v1.1.0"
	"github.com/kylelemons/godebug v1.1.0/go.mod"
	"github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822"
	"github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822/go.mod"
	"github.com/prometheus/client_golang v1.24.1"
	"github.com/prometheus/client_golang v1.24.1/go.mod"
	"github.com/prometheus/client_model v0.6.3"
	"github.com/prometheus/client_model v0.6.3/go.mod"
	"github.com/prometheus/common v0.72.0"
	"github.com/prometheus/common v0.72.0/go.mod"
	"github.com/prometheus/procfs v0.22.0"
	"github.com/prometheus/procfs v0.22.0/go.mod"
	"github.com/stretchr/testify v1.12.1"
	"github.com/stretchr/testify v1.12.1/go.mod"
	"golang.org/x/exp v0.0.0-20261005173118-76772065c9b0"
	"golang.org/x/exp v0.0.0-20261005173118-76772065c9b0/go.mod"
	"golang.org/x/sys v0.48.0"
	"golang.org/x/sys v0.48.0/go.mod"
	"google.golang.org/protobuf v1.36.12"
	"google.golang.org/protobuf v1.36.12/go.mod"
	"go.uber.org/goleak v1.3.0"
	"go.uber.org/goleak v1.3.0/go.mod"
	"go.yaml.in/yaml/v2 v2.4.4"
	"go.yaml.in/yaml/v2 v2.4.4/go.mod"
	"go.yaml.in/yaml/v3 v3.0.5"
	"go.yaml.in/yaml/v3 v3.0.5/go.mod"
)
go-module_set_globals
SRC_URI+="${EGO_SUM_SRC_URI}"

S="${WORKDIR}/${PN}-${P}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

DEPEND="
	acct-group/tibber-exporter
	acct-user/tibber-exporter
"
BDEPEND=">=dev-lang/go-1.25"
RDEPEND="${DEPEND}"

src_compile() {
	ego build
}

src_install() {
	dobin ${PN}
	dodoc *.md
	dodoc -r grafana
	newinitd "${FILESDIR}"/${PN}.initd ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	systemd_dounit "${FILESDIR}/${PN}.service"
}

pkg_postinst() {
	elog "To complete the installation get your Tibber token at"
	elog "https://developer.tibber.com"
	elog "and put it as TIBBER_TOKEN in /etc/conf.d/tibber-exporter file"
}
