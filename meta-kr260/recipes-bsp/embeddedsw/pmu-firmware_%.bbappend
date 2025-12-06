KR260_BASE_MACHINE ?= "k26-smk-kr-sdt"
PMU_FIRMWARE_DEPLOY_DIR:k26-smk-kr-sdt = "${TOPDIR}/tmp-k26-smk-kr-sdt-microblaze-pmu/deploy/images/${MACHINE}"

do_deploy:append:k26-smk-kr-sdt() {
    cd ${DEPLOYDIR}

    for ext in elf manifest bin; do
        latest=$(ls -t pmu-firmware-${KR260_BASE_MACHINE}--*.${ext} 2>/dev/null | head -1 || true)
        dst="pmu-firmware-${MACHINE}.${ext}"

        if [ -n "${latest}" ]; then
            rm -f ${dst}
            ln -sf ${latest} ${dst}
        fi
    done

    legacy_dir="${TOPDIR}/tmp-glibc-k26-smk-kr-sdt-microblaze-pmu"
    current_dir="${TOPDIR}/tmp-k26-smk-kr-sdt-microblaze-pmu"
    if [ -d "${current_dir}" ]; then
        ln -sfn "${current_dir}" "${legacy_dir}"
    fi
}
