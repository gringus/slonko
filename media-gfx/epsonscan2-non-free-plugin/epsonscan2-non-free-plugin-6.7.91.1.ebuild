# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit rpm

DESCRIPTION="Plugins for Epson Scan 2"
HOMEPAGE="https://download-center.epson.com"

REL="23"
PLUGIN_VERSION="1.0.0.6-1"

SRC_URI="https://download-center.epson.com/f/module/ca230f11-7cf6-41ef-8af5-76c8c76c63d0/epsonscan2-bundle-${PV}_${REL}.x86_64.rpm.tar.gz"
S=${WORKDIR}

LICENSE="EPSON"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="media-gfx/epsonscan2"
RESTRICT="bindist mirror strip fetch"

pkg_nofetch() {
	einfo "Please download ${SRC_URI}"
	einfo "manually using your browser and move it to your distfiles directory."
}

src_unpack() {
	default
	rpm_unpack "./epsonscan2-bundle-${PV}${REL}.x86_64.rpm/plugins/${PN}-${PLUGIN_VERSION}.x86_64.rpm"
}

src_install() {
	mv "usr/share/doc/${PN}-${PLUGIN_VERSION}" "usr/share/doc/${P}" || die
	insinto /usr
	doins -r usr/share
	doins -r usr/lib64
	doins -r usr/libexec
	# Fix permissions
	find "${ED}/usr/lib"* -type f -exec chmod 0755 {} +
}
