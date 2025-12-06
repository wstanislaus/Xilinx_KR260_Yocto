SUMMARY = "Resize block device partition helper"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://resize-part"

S = "${WORKDIR}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit allarch

RDEPENDS:${PN} = "parted e2fsprogs-resize2fs"

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${datadir}/resize_fs
    install -m 0755 ${WORKDIR}/resize-part ${D}${datadir}/resize_fs/
    ln -sf -r ${datadir}/resize_fs/resize-part ${D}${bindir}/resize-part
}

FILES:${PN} += "${datadir}"
