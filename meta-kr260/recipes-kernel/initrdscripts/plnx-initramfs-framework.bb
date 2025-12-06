# Initramfs framework
# Extends standard initramfs-framework with custom modules

SUMMARY = "Initramfs framework modules"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit allarch

# Depend on standard initramfs-framework
RDEPENDS:${PN} = "initramfs-framework"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://searche2fs"

S = "${WORKDIR}"

PACKAGES = " \
    plnx-initramfs-module-searche2fs \
    plnx-initramfs-module-scripts \
"

do_install() {
    install -d ${D}/init.d
    # Install searche2fs as 85-searche2fs so it runs before rootfs module (90-rootfs)
    # This prevents rootfs module from trying to mount /dev/ram0
    install -m 0755 ${WORKDIR}/searche2fs ${D}/init.d/85-searche2fs
}

# Provide compatibility packages that map to standard initramfs modules
# Note: plnx-initramfs-module-scripts is a virtual package for dependency tracking only
SUMMARY:plnx-initramfs-module-scripts = "Initramfs scripts module"
RDEPENDS:plnx-initramfs-module-scripts = "initramfs-framework-base"
FILES:plnx-initramfs-module-scripts = ""
ALLOW_EMPTY:plnx-initramfs-module-scripts = "1"

SUMMARY:plnx-initramfs-module-searche2fs = "PING NFS server ip and mount NFS filesystem"
RDEPENDS:plnx-initramfs-module-searche2fs = "initramfs-framework-base plnx-initramfs-module-scripts"
FILES:plnx-initramfs-module-searche2fs = "/init.d/85-searche2fs"

