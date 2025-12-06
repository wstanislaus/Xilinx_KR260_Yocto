# Initramfs image with custom NFS mounting scripts
# This creates an initramfs image that includes the plnx-initramfs-framework modules

SUMMARY = "Initramfs image with custom NFS mounting scripts"
DESCRIPTION = "A minimal initramfs image that includes custom modules for NFS mounting"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Inherit core-image to create a minimal rootfs
inherit core-image

# Use cpio.gz format for initramfs
IMAGE_FSTYPES = "cpio.gz"

# Minimal packages for initramfs
IMAGE_INSTALL = " \
    initramfs-framework-base \
    initramfs-module-udev \
    initramfs-module-rootfs \
    plnx-initramfs-module-searche2fs \
    plnx-initramfs-module-scripts \
    base-passwd \
    base-files \
    busybox \
    util-linux-mount \
    util-linux-umount \
    e2fsprogs-e2fsck \
    e2fsprogs-mke2fs \
    nfs-utils-client \
    iputils-ping \
    netbase \
"

# Remove unnecessary features for minimal initramfs
IMAGE_FEATURES = ""
NO_RECOMMENDATIONS = "1"

# Keep image small
IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

# Create symlink without .rootfs suffix for kernel bundling
# The kernel bundling process expects the file without .rootfs
# Use do_deploy which runs after the image is created and deployed
do_deploy:append() {
    DEPLOY_DIR="${DEPLOY_DIR_IMAGE}"
    IMAGE_NAME="${IMAGE_NAME}"
    SOURCE_FILE="${DEPLOY_DIR}/${IMAGE_NAME}.rootfs.cpio.gz"
    TARGET_FILE="${DEPLOY_DIR}/${PN}-${MACHINE}.cpio.gz"

    if [ -f "${SOURCE_FILE}" ] && [ ! -e "${TARGET_FILE}" ]; then
        cd "${DEPLOY_DIR}" && ln -sf "${IMAGE_NAME}.rootfs.cpio.gz" "${PN}-${MACHINE}.cpio.gz"
        bbnote "Created symlink for kernel bundling: ${TARGET_FILE} -> ${IMAGE_NAME}.rootfs.cpio.gz"
    fi
}
