KR260_BASE_MACHINE ?= "k26-smk-kr-sdt"

do_deploy:append:k26-smk-kr-sdt() {
    cd ${DEPLOYDIR}

    for ext in elf manifest; do
        latest=$(ls -t fsbl-${KR260_BASE_MACHINE}--*.${ext} 2>/dev/null | head -1 || true)
        dst="fsbl-${MACHINE}.${ext}"

        if [ -n "${latest}" ]; then
            rm -f ${dst}
            ln -sf ${latest} ${dst}
        fi
    done

    legacy_dir="${TOPDIR}/tmp-glibc-k26-smk-kr-sdt-cortexa53-fsbl"
    current_dir="${TOPDIR}/tmp-k26-smk-kr-sdt-cortexa53-fsbl"
    if [ -d "${current_dir}" ]; then
        ln -sfn "${current_dir}" "${legacy_dir}"
    fi
}
