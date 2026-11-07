# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="AMD XDNA NPU firmware (userspace-only: no out-of-tree kernel module)"
HOMEPAGE="https://github.com/amd/xdna-driver"

# Firmware pins mirrored from istitov/stuff xdna-driver-2.21.75-r2; the
# amd-ipu-staging branch requires manual commit selection (upstream issue
# 1236). Local fork: monolithic kernels (CONFIG_DRM_ACCEL_AMDXDNA=y, no
# modules) cannot build the OOT module, and fastflowlm only needs the
# package present as a driver+firmware guarantee.
FW_COMMIT=9c532be0fe8d6ac30e8a5e1c0b54a88ae94f50b6

declare -Ag FIRMWARES=(
	[1502_00/npu.sbin.1.5.5.391]=npu.dev.sbin
	[17f0_00/npu.sbin.0.7.22.185]=npu.dev.sbin
	[17f0_10/1.7_npu.sbin.1.1.2.64]=npu.dev.sbin
	[17f0_11/1.7_npu.sbin.1.1.2.65]=npu.dev.sbin
)

FW_URI_PREFIX=https://gitlab.com/kernel-firmware/drm-firmware/-/raw/${FW_COMMIT}/amdnpu

SRC_URI=" "
for fw in "${!FIRMWARES[@]}"; do
	SRC_URI+="${FW_URI_PREFIX}/${fw} -> ${FW_COMMIT:0:6}-${fw%%/*}__${FIRMWARES[${fw}]} "
done

S="${WORKDIR}"

LICENSE="linux-fw-redistributable"
SLOT="0"
KEYWORDS="~amd64"

src_install() {
	local fw dir src_filename
	for fw in "${!FIRMWARES[@]}"; do
		dir="${fw%%/*}"
		src_filename="${FW_COMMIT:0:6}-${dir}__${FIRMWARES[${fw}]}"
		insinto "/lib/firmware/amdnpu/${dir}"
		newins "${DISTDIR}/${src_filename}" "${FIRMWARES[${fw}]}"
	done
}
