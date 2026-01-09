# Ensure kernel-devsrc uses the built kernel's config (which has our custom config)
# The kernel-devsrc package installs kernel source for SDK development
# We want it to use the .config from the build directory that was built with our custom config

do_install:append() {
	# Find the kernel build directory and its .config
	# The kernel was built with our custom config in do_configure
	# kernel-devsrc inherits from kernel.bbclass, so we can access kernel variables
	KERNEL_CONFIG_SOURCE=""
	
	# The kernel build directory is typically ${B} in the kernel recipe
	# But in kernel-devsrc, we need to find the kernel's work directory
	# kernel-devsrc uses ${S} which is the kernel source, but the .config is in the build dir
	
	# Try to find the kernel's work directory by looking for the kernel recipe's build output
	# The kernel's .config should be in the kernel work directory's build subdirectory
	KERNEL_WORK_DIR=$(find "${TMPDIR}/work" -path "*/linux-xlnx/*" -type d -name "linux-*-standard-build" 2>/dev/null | head -1)
	
	if [ -n "${KERNEL_WORK_DIR}" ] && [ -f "${KERNEL_WORK_DIR}/.config" ]; then
		KERNEL_CONFIG_SOURCE="${KERNEL_WORK_DIR}/.config"
		bbnote "Found kernel build config: ${KERNEL_CONFIG_SOURCE}"
	else
		# Try to find any .config in kernel work directories
		KERNEL_CONFIG_SOURCE=$(find "${TMPDIR}/work" -path "*/linux-xlnx/*/.config" -type f 2>/dev/null | head -1)
		if [ -n "${KERNEL_CONFIG_SOURCE}" ]; then
			bbnote "Found kernel config in work directory: ${KERNEL_CONFIG_SOURCE}"
		fi
	fi
	
	# Fallback: try to get config from meta-kr260/configs
	if [ -z "${KERNEL_CONFIG_SOURCE}" ] || [ ! -f "${KERNEL_CONFIG_SOURCE}" ]; then
		for layer in ${BBLAYERS}; do
			if [ -f "${layer}/conf/layer.conf" ] && grep -q "kr260" "${layer}/conf/layer.conf" 2>/dev/null; then
				if [ -f "${layer}/configs/kernel.config" ]; then
					KERNEL_CONFIG_SOURCE="${layer}/configs/kernel.config"
					bbnote "Using kernel config from layer: ${KERNEL_CONFIG_SOURCE}"
					break
				fi
			fi
		done
	fi
	
	# If we found a config, ensure it's used in the installed kernel source
	# kernel-devsrc installs to ${D}${KERNEL_SRC_PATH} (typically /usr/src/kernel)
	# and also creates symlinks in /usr/lib/modules/*/build
	if [ -n "${KERNEL_CONFIG_SOURCE}" ] && [ -f "${KERNEL_CONFIG_SOURCE}" ]; then
		# Find where kernel-devsrc installed the kernel source
		KERNEL_SRC_INSTALL_DIR="${D}${KERNEL_SRC_PATH}"
		
		# Also check the modules build directory which is what SDK users actually use
		KERNEL_MODULES_BUILD_DIR=$(find "${D}" -path "*/usr/lib/modules/*/build" -type d 2>/dev/null | head -1)
		
		if [ -n "${KERNEL_SRC_INSTALL_DIR}" ] && [ -d "${KERNEL_SRC_INSTALL_DIR}" ]; then
			bbnote "Copying kernel config to kernel-devsrc: ${KERNEL_SRC_INSTALL_DIR}/.config"
			cp "${KERNEL_CONFIG_SOURCE}" "${KERNEL_SRC_INSTALL_DIR}/.config" || true
		fi
		
		if [ -n "${KERNEL_MODULES_BUILD_DIR}" ] && [ -d "${KERNEL_MODULES_BUILD_DIR}" ]; then
			bbnote "Copying kernel config to modules build directory: ${KERNEL_MODULES_BUILD_DIR}/.config"
			cp "${KERNEL_CONFIG_SOURCE}" "${KERNEL_MODULES_BUILD_DIR}/.config" || true
		fi
		
		bbnote "kernel-devsrc configured with custom kernel config"
	else
		bbwarn "Could not find kernel config for kernel-devsrc"
	fi
}

