# KR260 kernel customizations

# Tell Yocto where to find patch files
FILESEXTRAPATHS:prepend:k26-smk-kr-sdt := "${THISDIR}/files:"

# Disable openamp-xilinx kmeta to avoid missing repository fetches
KMETA:k26-smk-kr-sdt = ""
SRC_URI:remove:k26-smk-kr-sdt = " file://openamp-xilinx-kmeta;type=kmeta;name=openamp-xilinx-kmeta;destsuffix=openamp-xilinx-kmeta"

# Apply watchdog petting interval patch
SRC_URI:append:k26-smk-kr-sdt = " file://0001-cadence-wdt-fix-petting-interval-to-1-second.patch"

# Configure initramfs image
# Use plnx-initramfs-image which includes NFS mounting scripts
INITRAMFS_IMAGE:k26-smk-kr-sdt = "plnx-initramfs-image"

# Set the initramfs image name to match the deployed .rootfs.cpio artifact
# (Yocto drops the timestamp if IMAGE_VERSION_SUFFIX="") so we add .rootfs here
# to avoid having to synthesise a separate symlink for the kernel class lookup
INITRAMFS_IMAGE_NAME:k26-smk-kr-sdt = "${INITRAMFS_IMAGE}-${MACHINE}.rootfs"

# Bundle the initramfs into the kernel image
INITRAMFS_IMAGE_BUNDLE:k26-smk-kr-sdt = "1"

# Ensure initramfs image is built before kernel bundling
# The kernel bundling happens in do_bundle_initramfs which runs after do_compile
# We need the initramfs image to be complete (with symlink) before that
DEPENDS:k26-smk-kr-sdt += "${INITRAMFS_IMAGE}"
do_bundle_initramfs[depends] += "${INITRAMFS_IMAGE}:do_image"

# Apply saved kernel config from meta-kr260/configs
do_configure:append:k26-smk-kr-sdt() {
	KERNEL_CONFIG_FILE=""
	for layer in ${BBLAYERS}; do
		if [ -f "${layer}/conf/layer.conf" ] && grep -q "kr260" "${layer}/conf/layer.conf" 2>/dev/null; then
			if [ -f "${layer}/configs/kernel.config" ]; then
				KERNEL_CONFIG_FILE="${layer}/configs/kernel.config"
				break
			fi
		fi
	done

	if [ -z "${KERNEL_CONFIG_FILE}" ]; then
		bbnote "No saved kernel config found, using default configuration"
		return
	fi

	# Find the kernel build directory where .config should be placed
	# The kernel build directory might be ${B} or a subdirectory like linux-*-standard-build
	KERNEL_BUILD_DIR="${B}"
	KERNEL_CONFIG_DST="${B}/.config"

	# Check if .config already exists in ${B}
	if [ ! -f "${KERNEL_CONFIG_DST}" ]; then
		# Try to find the standard build directory or any .config file
		FOUND_CONFIG=$(find "${B}" -name ".config" -type f 2>/dev/null | head -1)
		if [ -n "${FOUND_CONFIG}" ]; then
			KERNEL_CONFIG_DST="${FOUND_CONFIG}"
			KERNEL_BUILD_DIR=$(dirname "${FOUND_CONFIG}")
		else
			# Try to find linux-*-standard-build directory
			FOUND_BUILD_DIR=$(find "${B}" -name "linux-*-standard-build" -type d 2>/dev/null | head -1)
			if [ -n "${FOUND_BUILD_DIR}" ]; then
				KERNEL_BUILD_DIR="${FOUND_BUILD_DIR}"
				KERNEL_CONFIG_DST="${FOUND_BUILD_DIR}/.config"
			fi
		fi
	fi

	if [ ! -d "${KERNEL_BUILD_DIR}" ]; then
		bbwarn "Kernel build directory not found, skipping config copy..."
		return
	fi

	cp "${KERNEL_CONFIG_FILE}" "${KERNEL_CONFIG_DST}"
	bbnote "Applied kernel config from: ${KERNEL_CONFIG_FILE} to ${KERNEL_CONFIG_DST}"

	# Run olddefconfig to update the config with any new/changed options
	cd "${KERNEL_BUILD_DIR}" && oe_runmake olddefconfig || bbwarn "olddefconfig failed, continuing anyway"

}

# Ensure configuration is up-to-date before compiling to avoid interactive prompts
do_compile:prepend:k26-smk-kr-sdt() {
	oe_runmake olddefconfig
}
