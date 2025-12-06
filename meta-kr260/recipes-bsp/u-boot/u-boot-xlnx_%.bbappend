# Apply master U-Boot config for the KR260 platform
do_configure:append:k26-smk-kr-sdt() {
	UBOOT_CONFIG_FILE=""
	for layer in ${BBLAYERS}; do
		if [ -f "${layer}/conf/layer.conf" ] && grep -q "kr260" "${layer}/conf/layer.conf" 2>/dev/null; then
			if [ -f "${layer}/configs/u-boot.config" ]; then
				UBOOT_CONFIG_FILE="${layer}/configs/u-boot.config"
				break
			fi
		fi
	done

	if [ -z "${UBOOT_CONFIG_FILE}" ] || [ ! -f "${B}/.config" ]; then
		bbwarn "Unable to apply U-Boot config"
		return
	fi

	cp "${UBOOT_CONFIG_FILE}" "${B}/.config"
	bbnote "Applied U-Boot config from: ${UBOOT_CONFIG_FILE}"
	cd "${B}" && oe_runmake olddefconfig
}
