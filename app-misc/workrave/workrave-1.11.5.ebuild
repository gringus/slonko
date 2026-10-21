# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..15} )

inherit cmake python-any-r1 xdg-utils

DESCRIPTION="Helpful utility to attack Repetitive Strain Injury (RSI)"
HOMEPAGE="https://workrave.org/"
MY_PV=$(ver_rs 1- '_')
SRC_URI="https://github.com/rcaelers/${PN}/archive/v${MY_PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${MY_PV}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

IUSE="dbus debug gstreamer gnome indicator +gtk mate pulseaudio qt6 test wayland xfce"
RESTRICT="!test? ( test )"
REQUIRED_USE="
	^^ ( gtk qt6 )
	gnome? ( dbus )
	indicator? ( dbus )
	mate? ( dbus )
	xfce? ( dbus )
"

RDEPEND="
	>=dev-libs/spdlog-1.10.0
	>=dev-libs/boost-1.73.0
	>=dev-libs/glib-2.56.0:2
	x11-libs/libX11
	x11-libs/libXtst
	gtk? (
		>=x11-themes/adwaita-icon-theme-43
		>=x11-libs/gtk+-3.22.0:3
		>=dev-cpp/gtkmm-3.22.0:3.0
	)
	qt6? (
		dev-qt/qtbase:6[dbus?]
		dev-qt/qtsvg:6
		dev-qt/qttools:6[linguist]
	)
	gstreamer? ( media-libs/gstreamer:1.0 )
	indicator? (
		>=dev-libs/libayatana-indicator-0.4:3
		dev-libs/libayatana-appindicator
		dev-libs/libdbusmenu[gtk3]
	)
	mate? ( >=mate-base/mate-panel-1.20.0 )
	pulseaudio? ( media-libs/libpulse )
	wayland? ( dev-libs/wayland )
	xfce? ( >=xfce-base/xfce4-panel-4.12 )
"
DEPEND="${RDEPEND}"

# dbus/jinja2 are used for build-time codegen only (cmake/modules/DBus.cmake
# generates .cc/.hh from .jinja templates); no python is used or installed at
# runtime, hence python-any-r1.  python_check_deps() makes the eclass skip
# interpreters lacking jinja2; without it upstream silently falls back to
# pip-installing jinja2 into a venv, which the network sandbox blocks.
# gettext is only needed for the Gtk+3 UI (the Qt UI uses Qt Linguist instead);
# the Gtk+3 build aborts with FATAL_ERROR if gettext is absent.
BDEPEND="
	>=dev-util/pkgconf-1.8.0
	gtk? ( >=sys-devel/gettext-0.21 )
	dbus? (
		${PYTHON_DEPS}
		$(python_gen_any_dep 'dev-python/jinja2[${PYTHON_USEDEP}]')
	)
	gnome? ( dev-libs/gobject-introspection )
"

pkg_setup() {
	python-any-r1_pkg_setup
}

python_check_deps() {
	use dbus && python_has_version "dev-python/jinja2[${PYTHON_USEDEP}]"
}

src_configure() {
	local mycmakeargs=(
		-DWITH_CCACHE=OFF
		-DWITH_DBUS=$(usex dbus)
		-DWITH_DBUSMENU=$(usex indicator) # hard requirement of indicator/appindicator support
		-DWITH_GNOME_CLASSIC_PANEL=OFF # needs libgnome-panel; no USE flag, GNOME Shell applet is the supported path
		-DWITH_GNOME_SHELL=$(usex gnome)
		-DWITH_GSTREAMER=$(usex gstreamer)
		-DWITH_INDICATOR=$(usex indicator)
		-DWITH_MATE=$(usex mate)
		-DWITH_PULSE=$(usex pulseaudio)
		-DWITH_TESTS=$(usex test)
		-DWITH_TRACING=$(usex debug)
		# WITH_UI only accepts "Qt" or "Gtk+3" (no "None")
		-DWITH_UI=$(usex qt6 Qt Gtk+3)
		-DWITH_WAYLAND=$(usex wayland)
		-DWITH_XFCE4=$(usex xfce)
	)
	cmake_src_configure
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
