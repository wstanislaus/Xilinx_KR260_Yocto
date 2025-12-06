# Point FSBL deploy lookup to the actual multiconfig tmp directory
# BitBake's default ${TMPDIR} expands to tmp-glibc, while the multiconfig
# builds still emit artifacts under ${TOPDIR}/tmp-<mc>. Adjust the path so
# the fsbl recipe can find the generated ELF/manifest.
FSBL_DEPLOY_DIR:k26-smk-kr-sdt = "${TOPDIR}/tmp-k26-smk-kr-sdt-cortexa53-fsbl/deploy/images/${MACHINE}"
